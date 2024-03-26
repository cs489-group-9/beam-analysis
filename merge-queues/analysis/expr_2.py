import sys
import logging
import pandas as pd
import numpy as np
from tqdm import tqdm
from google.cloud import bigquery
from collections import defaultdict

client = bigquery.Client()

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


def batch_commits_and_sum_build_times(
    commits: pd.DataFrame, workflow_runs: pd.DataFrame, batch_max_wait_time: int
):
    """
    Given a DataFrame of commits, batch them into groups based on the time between commits
    """
    total_build_time = 0
    total_batches = 0
    total_delay = 0
    current_batch_workflows = defaultdict(list)
    current_batch_end_time = commits.iloc[0]["date"] + pd.Timedelta(
        minutes=batch_max_wait_time
    )

    for i in range(len(commits)):
        curr_commit = commits.iloc[i]

        if curr_commit["date"] > current_batch_end_time:
            for _, build_times in current_batch_workflows.items():
                total_build_time += np.mean(build_times)

            current_batch_end_time = curr_commit["date"] + pd.Timedelta(
                minutes=batch_max_wait_time
            )
            current_batch_workflows = defaultdict(list)
            total_delay += batch_max_wait_time
            total_batches += 1

        workflows_for_commit = workflow_runs.loc[
            workflow_runs["head_sha"] == curr_commit["sha"]
        ]
        for _, workflow in workflows_for_commit.iterrows():
            current_batch_workflows[workflow["workflow_id"]].append(
                workflow["build_minutes"]
            )

    # Process the last batch
    for _, build_times in current_batch_workflows.items():
        total_build_time += np.mean(build_times)
    total_delay += batch_max_wait_time
    total_batches += 1

    return (total_build_time, total_delay, total_delay / total_batches)


def run_monte_carlo_simulation(
    all_commits: pd.DataFrame, workflow_runs: pd.DataFrame, iterations: int = 10
):
    simulation_results = []
    for _ in tqdm(range(iterations)):
        bootstrap_sample = all_commits.sample(
            n=1000, replace=True
        ).sort_index()  # retain original sorted order which which started at the earliest commit in range and is ascending by time

        merge_queue_batch_delay = np.random.randint(1, 61)
        build_time, total_delay, mean_delay = batch_commits_and_sum_build_times(
            bootstrap_sample, workflow_runs, merge_queue_batch_delay
        )

        simulation_results.append(
            {
                "merge_queue_batch_delay": merge_queue_batch_delay,
                "total_ci_minutes": build_time,
                "total_delay": total_delay,
                "mean_delay": mean_delay,
            }
        )

    simulation_results_df = pd.DataFrame(simulation_results)

    return simulation_results_df


def run_control(workflow_runs: pd.DataFrame):
    return workflow_runs["build_minutes"].sum()


def main():
    query_for_commit_shas = "SELECT sha, commit.committer.date FROM `scientific-glow-417622.beam.commits` ORDER BY commit.committer.date ASC"
    query_for_workflow_runs = """
        SELECT
            workflow_run.head_sha,
            workflow_run.name,
            workflow_run.workflow_id,
            workflow_run.run_started_at,
            workflow_run.created_at,
            workflow_run.updated_at,
            TIMESTAMP_DIFF(workflow_run.updated_at, workflow_run.created_at, SECOND) / 60.0 AS build_minutes
        FROM
            `scientific-glow-417622.beam.commits` AS commits
        CROSS JOIN
            `scientific-glow-417622.beam.push_and_schedule_workflows`,
            UNNEST(workflow_runs) AS workflow_run
        WHERE
            commits.sha = workflow_run.head_sha AND workflow_run.event = 'push'
            """
    logger.info("Fetching data from BigQuery...")
    commits_df = client.query_and_wait(query_for_commit_shas).to_dataframe()
    workflow_runs_df = client.query_and_wait(query_for_workflow_runs).to_dataframe()

    logger.info("Calculating control Build minutes...")
    control_build_minutes = run_control(workflow_runs_df)
    logger.info(f"Total Build Time for Control is: {control_build_minutes}")

    logger.info("Running Monte Carlo Simulation...")
    simulation_results_df = run_monte_carlo_simulation(
        commits_df, workflow_runs_df, iterations=10
    )
    print(simulation_results_df)
    print(control_build_minutes)


if __name__ == "__main__":
    main()

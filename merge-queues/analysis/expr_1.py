import sys
import logging
import pandas as pd
import numpy as np
from tqdm import tqdm
from google.cloud import bigquery
from collections import defaultdict
import matplotlib.pyplot as plt

client = bigquery.Client(project="scientific-glow-417622")

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


def threshold_vs_developer_velocity(
    commits: pd.DataFrame, workflow_runs: pd.DataFrame, threshold: int
):
    passing_commits = 0
    for i in range(len(commits)):
        curr_commit = commits.iloc[i]
        failures, successes = 0, 0

        workflows_for_commit = workflow_runs.loc[
            workflow_runs["head_sha"] == curr_commit["sha"]
        ]

        for _, workflow in workflows_for_commit.iterrows():
            if workflow["conclusion"] == "success":
                successes += 1
            else:
                failures += 1

        if successes + failures > 0:
            passing_percentage = successes / (successes + failures)
            if passing_percentage * 100 > threshold:
                passing_commits += 1
    return passing_commits


def run_monte_carlo_simulation(
    commits: pd.DataFrame, workflow_runs: pd.DataFrame, iterations: int
):
    simulation_results = []
    for _ in tqdm(range(iterations)):
        threshold_value = np.random.randint(50, 100)
        passing_commits = threshold_vs_developer_velocity(
            commits, workflow_runs, threshold_value
        )
        simulation_results.append(
            {"threshold_value": threshold_value, "passing_commits": passing_commits}
        )
    simulation_results_df = pd.DataFrame(simulation_results)
    return simulation_results_df


def plot_simulation_results(simulation_results_df: pd.DataFrame):
    # Plot a scatterplot comparing total_ci_minutes vs total_delay
    plt.scatter(
        simulation_results_df["threshold_value"],
        simulation_results_df["passing_commits"],
        label="Monte Carlo Simulation Results",
    )
    plt.xlabel("Threshold Value")
    plt.ylabel("Passing Commits")
    plt.title("Threshold Value vs Passing Commits")
    plt.legend()
    plt.show()


def main():
    query_for_commit_shas = """
        SELECT sha, commit.committer.date 
        FROM `scientific-glow-417622.beam.commits` 
        ORDER BY commit.committer.date ASC
        """
    query_for_workflow_runs = """
    SELECT
        workflow_run.head_sha,
        workflow_run.name,
        workflow_run.conclusion,
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
        commits.sha = workflow_run.head_sha AND workflow_run.event = 'schedule'
        """

    logger.info("Fetching data from BigQuery...")
    commits_df = client.query_and_wait(query_for_commit_shas).to_dataframe()
    workflow_runs_df = client.query_and_wait(query_for_workflow_runs).to_dataframe()

    logger.info("Running Monte Carlo Simulation...")
    simulation_results_df = run_monte_carlo_simulation(
        commits_df, workflow_runs_df, iterations=10
    )
    plot_simulation_results(simulation_results_df)


if __name__ == "__main__":
    main()

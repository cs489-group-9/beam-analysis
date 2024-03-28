import os
import sys
import json
import logging
from tqdm import tqdm
from typing import List
from dotenv import load_dotenv
from github_api import GithubAPI
from google.cloud import storage

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


def save_to_file(data, filename):
    with open(filename, "w+") as file:
        json.dump(data, file)


def fetch_and_upload_commits(api: GithubAPI):
    logger.info("Fetching commits...")
    total_commits = []
    for i in tqdm(range(1, 11)):
        commits = api.fetchData(
            f"commits?per_page=100&page={i}&until=2024-03-24T00:00:00Z"
        )
        total_commits.extend(commits)

    commit_shas = set([commit["sha"] for commit in total_commits])
    save_to_file(total_commits, "commits.json")

    return commit_shas


def fetch_and_upload_push_and_schedule_workflow_runs(
    api: GithubAPI, commit_shas: List[str]
):
    logger.info("Fetching and uploading push and schedule workflow runs...")
    workflow_runs = []
    for sha in tqdm(commit_shas):
        push_runs = api.fetchData(f"actions/runs?event=push&head_sha={sha}")
        schedule_runs = api.fetchData(f"actions/runs?event=schedule&head_sha={sha}")
        workflow_runs.append(push_runs)
        workflow_runs.append(schedule_runs)

    save_to_file(workflow_runs, "workflow_runs_push.json")


def fetch_and_upload_pull_requests(api: GithubAPI, commit_shas: List[str]):
    logger.info("Fetching and uploading pull requests...")
    pull_requests = []
    for sha in tqdm(commit_shas):
        prs = api.fetchData(f"commits/{sha}/pulls")
        pull_requests.extend(prs)

    save_to_file(pull_requests, "pull_requests.json")
    return [pr["head"]["sha"] for pr in pull_requests]


def fetch_and_upload_pull_request_and_pull_request_target_workflow_runs(
    api: GithubAPI, pull_request_head_shas
):
    logger.info(
        "Fetching and uploading pull request and pull request target workflow runs..."
    )
    workflow_runs = []
    for sha in tqdm(pull_request_head_shas):
        pr_runs = api.fetchData(f"actions/runs?event=pull_request&head_sha={sha}")
        pr_target_runs = api.fetchData(
            f"actions/runs?event=pull_request_target&head_sha={sha}"
        )
        workflow_runs.append(pr_runs)
        workflow_runs.append(pr_target_runs)

    save_to_file(workflow_runs, "workflow_runs_pull_requests.json")

    return []


def main():
    load_dotenv()
    api = GithubAPI(os.getenv("GITHUB_TOKEN"))
    commit_shas = fetch_and_upload_commits(api)
    file = open("commit_shas.txt", "w+")
    for sha in commit_shas:
        file.write(f"{sha}\n")
    file.close()
    fetch_and_upload_push_and_schedule_workflow_runs(api, commit_shas)
    pr_head_commits = fetch_and_upload_pull_requests(api, commit_shas)
    file = open("pr_head_commit_shas.txt", "w+")
    for sha in pr_head_commits:
        file.write(f"{sha}\n")
    file.close()
    fetch_and_upload_pull_request_and_pull_request_target_workflow_runs(
        api, pr_head_commits
    )


if __name__ == "__main__":
    main()

# beam-analysis

This repository contains Group 9s Artifact 3 implementations for the CS 489 Project

## How to use the release automation script
1. Copy all files from the `release` folder into the beam repo (main directory)
2. Install GitHub CLI on your machine (I couldn't install onto school machines, but for my personal mac laptop, I ran `brew install gh`)
3. Authenticate Github using the command `gh auth login`
4. Run `./release`

## How to set up your environment for running everything in merge-queues

The directory `merge-queues` contains the improvements described in Improvement 1 and Improvement 2, along with the script that we used for mining commits and workflow data from the Github API.

**Please note, that while we do include a `data_fetching/fetch_data.py` script which we implemented for mining data and ran once, it does not need to be run again. All the data needed from the API has already been uploaded into BigQuery.**

However, if you would like to replicate our steps to test the functional correctness of the `data_fetching/fetch_data.py` script, we have included our Github Token in the submitted report. To begin, create a `.env` file in `data_fetching/` and add this line:

```
GITHUB_TOKEN=<the token provided in the report>
```

Next, to run `fetch_data.py` or any of the python notebooks provided you need to set up the `gcloud` CLI locally. Faizaan, one of the people in the team has made a post in Piazza requesting your email addresses to add you to the GCP Project. Please follow the instructions here to set up GCloud for your operating system:

https://cloud.google.com/sdk/docs/install

After you have gcloud set up and running on your computer you should be easily able execute commands using it. During the initialization process, make sure you are log into the account provided to us and set the project to `scientific-glow-417622` (this is our project). If you did not authenticate, or are not sure if you have, please run this command:

```
gcloud auth login
```

This will prompt you to open your browser and sign in.

You will also need authenticate gcloud to provide [application default credentials (ADC)](https://cloud.google.com/docs/authentication/gcloud#gcloud-credentials). You can do this by running the below command, which should also prompt you to log in.

```
gcloud auth application-default login
```

The url linked also provides documentation on how to do this.

### (Optional) Replicating what we did for adding Github Data to BigQuery

Running `fetch_data.py` will generate json files that will be saved locally. Note that it also generates .txt files, but these can be ignored as they are written as a failsafe to cache intermediary results.

**IMPORTANT NOTE FOR MARKER:**

**Since the files have already been generated we would encourage you to not perform the following steps, as reuploading the files would require you to overwrite the tables we have already created.**

**You will need to delete our tables to make sure they get created with the same names to ensure our notebooks can still query from them which could inadvertently break our notebooks if the data upload does not happen properly.**

**None of the steps for uploading actually relate to our Experimental Design and Results. It was just preliminary work that we had to do to get the data we needed, and we explain it here for transparency.**

However, for the sake of visibility, here are the following manual steps we took to get our project into BigQuery. They assume that BigQuery does not contain tables with the names that already exist, however BigQuery currently does have these tables.

Due to formatting differences between Python JSON arrays and what's accepted in BigQuery, we need to modify the format manually before we upload it to BigQuery. 

```
cat <file_name>.json | jq -c '.[]' > <filename>_bq_compat.json
```

So, for the generated commits.json file, this would be:
```
cat commits.json | jq -c '.[]' > <filename>.json
```

We performed this operation on every single json file exported. These were `commits.json`, `workflow_runs_push.json`, `pull_requests.json` and `workflow_runs_pull_requests.json`.

You will need the `jq` command installed to do this, which you can find [here](https://jqlang.github.io/jq/)

This is a common issue and the steps to solve it are straight from GCP, [documented here](https://cloud.google.com/knowledge/kb/parse-error-while-creating-bigquery-table-using-a-json-file-with-an-autodetect-flag-000004311).

After you've done this for all the generated files, you can create new tables and upload them to BigQuery by going here: https://console.cloud.google.com/bigquery?referrer=search&project=scientific-glow-417622&ws=!1m0

From there, click the right facing arrow next to `scientific-glow-417622` in the explorer, click the arrow next to be `beam` to view the tables created. Your Explorer should look like this

Then, click the three vertical dots next to the beam logo, and click Create Table, which will open a form. For the commits.json, it would be filled out like this, and we would upload the file from our local computer

<Insert image here>

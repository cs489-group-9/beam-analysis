#!/usr/bin/env bash
printf "\nStart the review-and-vote thread on the dev@ mailing list by following the instructions \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#vote-and-validate-the-release-candidate\e\\here\n\e]8;;\e\ \n"
read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi

printf "\n==================== 4.1 Run validations using run_rc_validation.sh =======================\n"
printf "\nPlease update required configurations listed in RC_VALIDATE_CONFIGS in script.config\n"

read -r -p "Done [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi
 
./release/src/main/scripts/run_rc_validation.sh

printf "\n\n Please complete the following:
* Check whether validations succeed by following console output instructions.
* Terminate streaming jobs and java injector.
* Run Java quickstart (wordcount) and mobile game examples with the staged artifacts. The easiest way to do this is by running the tests on GitHub Actions.
* Other manual validation will follow, but this will at least validate that the staged artifacts can be used.
    - Go to https://github.com/apache/beam/actions/workflows/beam_PostRelease_NightlySnapshot.yml/.
    - Click 'Run Workflow'.
    - Set RELEASE to 2.xx.0, and set SNAPSHOT_URL to point to the staged artifacts in Maven central (https://repository.apache.org/content/repositories/orgapachebeam-NNNN/).
    - Click "Build".
* Sign up spreadsheet.
* Vote in the release thread.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi


read -r -p "What's the Prepourl key found in the RC vote email sent by Release Manager: " KEY
read -r -p "What's the Pver release version found in the RC vote email sent by Release Manager: " RELEASE_VERSION


printf "\n==================== 4.2.1.1 Java Quickstart Validation: Direct Runner =======================\n"
./gradlew :runners:direct-java:runQuickstartJavaDirect \
-Prepourl=https://repository.apache.org/content/repositories/orgapachebeam-${KEY} \
-Pver=${RELEASE_VERSION}

printf "\n==================== 4.2.1.2 Java Quickstart Validation: Flink Local Runner =======================\n"
./gradlew :runners:flink:1.13:runQuickstartJavaFlinkLocal \
-Prepourl=https://repository.apache.org/content/repositories/orgapachebeam-${KEY} \
-Pver=${RELEASE_VERSION}

printf "\n==================== 4.2.1.3 Java Quickstart Validation: Spark Local Runner =======================\n"
./gradlew :runners:spark:3:runQuickstartJavaSpark \
-Prepourl=https://repository.apache.org/content/repositories/orgapachebeam-${KEY} \
-Pver=${RELEASE_VERSION}

printf "\n==================== 4.2.1.4 Java Quickstart Validation: Dataflow Runner =======================\n"
read -r -p "What's your GCP project: " YOUR_GCP_PROJECT
read -r -p "What's your GCP bucket: " YOUR_GCP_BUCKET

./gradlew :runners:google-cloud-dataflow-java:runQuickstartJavaDataflow \
-Prepourl=https://repository.apache.org/content/repositories/orgapachebeam-${KEY} \
-Pver=${RELEASE_VERSION} \
-PgcpProject=${YOUR_GCP_PROJECT} \
-PgcsBucket=${YOUR_GCP_BUCKET}


printf "\n==================== 4.2.2 Java Mobile Game(UserScore, HourlyTeamScore, Leaderboard) =======================\n"

# Create your own BigQuery dataset
read -r -p "Choose your BigQuery dataset name: " YOUR_DATASET
bq mk --project_id=${YOUR_GCP_PROJECT} ${YOUR_DATASET}

# Create your PubSub topic
read -r -p "Choose your PubSub topic name: " YOUR_PROJECT_PUBSUB_TOPIC
gcloud alpha pubsub topics create --project=${YOUR_GCP_PROJECT} ${YOUR_PROJECT_PUBSUB_TOPIC}


# Setup your service account
printf "\n\n Please go to the IAM console in your project to create a service account as project owner.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi

read -r -p "What's the filepath containing your Google Cloud IAM service account key (json): " YOUR_KEY_JSON
read -r -p "What's your Google Cloud IAM service account name: " YOUR_SERVICE_ACCOUNT_NAME
read -r -p "What's your project name: " YOUR_PROJECT_NAME}

gcloud iam service-accounts keys create ${YOUR_KEY_JSON} --iam-account ${YOUR_SERVICE_ACCOUNT_NAME}@${YOUR_PROJECT_NAME}
export GOOGLE_APPLICATION_CREDENTIALS=${YOUR_KEY_JSON}

./gradlew :runners:google-cloud-dataflow-java:runMobileGamingJavaDataflow \
 -Prepourl=https://repository.apache.org/content/repositories/orgapachebeam-${KEY} \
 -Pver=${RELEASE_VERSION} \
 -PgcpProject=${YOUR_GCP_PROJECT} \
 -PgcsBucket=${YOUR_GCP_BUCKET} \
 -PbqDataset=${YOUR_DATASET} -PpubsubTopic=${YOUR_PROJECT_PUBSUB_TOPIC}

printf "\n==================== 4.2.3 Python Quickstart(batch & streaming), MobileGame(UserScore, HourlyTeamScore) =======================\n"

printf "\n\n Please do the following:
* Create a new PR in apache/beam.
* In comment area, type in Run Python ReleaseCandidate to trigger validation.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi

printf "\n==================== 4.2.4 Python Leaderboard & GameStats =======================\n"

# Get staging RC
wget https://dist.apache.org/repos/dist/dev/beam/2.5.0/* 

# Verify the hashes
sha512sum -c apache-beam-2.5.0-python.tar.gz.sha512
sha512sum -c apache-beam-2.5.0-source-release.tar.gz.sha512

# Build SDK
sudo apt-get install unzip
unzip apache-beam-2.5.0-source-release.tar.gz
python setup.py sdist

# Setup virtual environment
python3 -m venv beam_env
. ./beam_env/bin/activate
pip install --upgrade pip setuptools wheel

# Install SDK
pip install dist/apache-beam-2.5.0.tar.gz
pip install dist/apache-beam-2.5.0.tar.gz[gcp]
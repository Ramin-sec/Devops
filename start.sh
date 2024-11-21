#!/bin/bash
set -e

if [ -z "${AZP-URL}" ]; then
  echo 1>&2 "error: missing AZP-URL environment variable"
  exit 1
fi

if [ -z "${AZP-TOKEN-FILE}" ]; then
  if [ -z "${AZP-TOKEN}" ]; then
    echo 1>&2 "error: missing AZP-TOKEN environment variable"
    exit 1
  fi

  AZP-TOKEN-FILE="/azp/.token"
  echo -n "${AZP-TOKEN}" > "${AZP-TOKEN-FILE}"
fi

unset AZP-TOKEN

if [ -n "${AZP-WORK}" ]; then
  mkdir -p "${AZP-WORK}"
fi

cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # If the agent has some running jobs, the configuration removal process will fail.
    # So, give it some time to finish the job.
    while true; do
      ./config.sh remove --unattended --auth "PAT" --token $(cat "${AZP-TOKEN-FILE}") && break

      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}

print_header() {
  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"
}

# Let the agent ignore the token env variables
export VSO-AGENT-IGNORE="AZP-TOKEN,AZP-TOKEN-FILE"

print_header "1. Determining matching Azure Pipelines agent..."

AZP-AGENT-PACKAGES=$(curl -LsS \
    -u user:$(cat "${AZP-TOKEN-FILE}") \
    -H "Accept:application/json" \
    "${AZP-URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH}&top=1")

AZP-AGENT-PACKAGE-LATEST-URL=$(echo "${AZP-AGENT-PACKAGES}" | jq -r ".value[0].downloadUrl")

if [ -z "${AZP-AGENT-PACKAGE-LATEST-URL}" -o "${AZP-AGENT-PACKAGE-LATEST-URL}" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that account "${AZP-URL}" is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and extracting Azure Pipelines agent..."

curl -LsS "${AZP-AGENT-PACKAGE-LATEST-URL}" | tar -xz & wait $!

source ./env.sh

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

print_header "3. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "${AZP-AGENT-NAME:-$(hostname)}" \
  --url "${AZP-URL}" \
  --auth "PAT" \
  --token $(cat "${AZP-TOKEN-FILE}") \
  --pool "${AZP-POOL:-Default}" \
  --work "${AZP-WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent..."

chmod +x ./run.sh

# To be aware of TERM and INT signals call ./run.sh
# Running it with the --once flag at the end will shut down the agent after the build is executed
./run.sh "$@" & wait $!
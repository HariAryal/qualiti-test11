#!/bin/bash

  set -ex

  API_KEY='2837388064bcad01'
  INTEGRATIONS_API_URL='https://3000-qualitiai-qualitiapi-51d2c33ux5c.ws-us51.gitpod.io'
  PROJECT_ID='3'
  CLIENT_ID='0975c80c0a24f22968f2c5a9e6603d0b'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-51d2c33ux5c.ws-us51.gitpod.io'
  INTEGRATION_JWT_TOKEN='b2f7252c8a8b829ab43a1b5c23507baa65361a64943516e2b87b5f5c8a2018078a8d596023ec3e58bdd571af2a2270147ed5e4dfe08ac49047e6123345446e94011ce532fb98c4a7e706d654b06cc4456ceff2ae00740e3b4e30a7581ee29fc37d4fdf0ee9685dec952525979492decf8ba037a18085be7e38d760e71debae3673bf50505e39a0e33d70d129e42fe431baf371e6c4020dc01b6bdb7f0883fc091b312d099b3a7d0a41ed6c54c85565431b6f554e330a0694c340ea33e7af9d65ad735d701c2da5f46fd233cd1f66cedec3b566e194d4d2f31f1225a64d4b2da71ae57ecc2f897ff36dd9cf2818a6f7e3167fc6511b60ce856d37d31b516803fe8dbaed7c25371d77327a445809ec513d|07d74449e6fbffdc030a9a64a4c94245|1fe3d7bb42817dff9ede1c79d264e995'

  sudo apt-get update -y
  sudo apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/public/api-keys/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  

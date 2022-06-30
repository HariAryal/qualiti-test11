#!/bin/bash

  set -ex

  API_KEY='1df2d88975bc9d4d'
  INTEGRATIONS_API_URL='https://api.qualiti-dev.com'
  PROJECT_ID='3'
  CLIENT_ID='7accab20bde942ea6fd5223432406d3b'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://api.qualiti-dev.com/public/api'
  INTEGRATION_JWT_TOKEN='e1144fb979cfd3e85525f5a7e557c91e2079210b3e3a34f0a5350046505c3745ad02448e07f747742adb4947c93d4801f08c94b13ea39b076175aff6e0647cbabf9bb5f74cddb01491d23c73ecb81c159422c2568fc2927c98b9859753abe04de350399ec76f1fa917d375ee23e88815db6c1b51a7541ac41abe20929d4ea477357759f856dbd55bc34c2fd479ffc85f98736efcf2a076767ec6d022f04e9e7960f747f6693edcf75d7b311764d2921b8123ec1e362054709596f92cf8abf0756a3bcda3c943959b929aaf71e5bdfc95bd192127a6916bef40728294e5365ed6ddce603217e9f406c102c3e502599b9d95f7a59d485affdfe53bf04b0e5f48fdd71c3e0544d01cbabf3f57225c9919db|e937f620253c5857cc444a3dbd63aea4|2f4532b0e0b21ea005bbb24e13647dfc'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
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
  

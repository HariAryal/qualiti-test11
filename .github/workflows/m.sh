#!/bin/bash

  set -ex

  API_KEY='<replace-with-api-key>'
  INTEGRATIONS_API_URL='https://api.qualiti-dev.com'
  PROJECT_ID='3'
  CLIENT_ID='dc2761a1634b1b2d1465196fadcc86b2'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://api.qualiti-dev.com/public/api'
  INTEGRATION_JWT_TOKEN='764275e459449b0287ddcacaec9f2e091b0c4e079e1a3bd03f18a75fb2f298a63dead775363f6f386e82d4753a5668115112fee78c81d1e9916c89c469771cb7287b1061d276ac8b0bcaa56c5111f19b158dca823f8e6bef08cec2f90d9de6338dfdcfc11868255d32cbf78d2a962e6b40a6a459ec33029f5a76c8f455dfab2bcb89ad8b0083ba16cc6c68c198144fde82779f034598ceabc16c56fc279121c76da6affb7cb289cf58ed86f0f2d7d3ba67801b42e0c8d1033856277d4ce7863e432813ecd4b63d0564f120606b6da4cbdb3b71e4d2b74d1cc897d6455fc043521c44b16211d44bc5355b81c469609def29507f0b138c48ed160e67ee8c46d072a9396cfcc322a62072fd7e05136bf015|8a5b25759237711a067526ee706156c5|ed7ac1244e0e445b948614e0db570612'

  sudo apt-get update -y
  sudo apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggeredBy=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client-id: '${CLIENT_ID}'' \
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
  

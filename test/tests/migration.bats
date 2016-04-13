# source docker helpers
. util/docker.sh

@test "Start Old Container" {
  start_container "test-migrate-old" "192.168.0.2"
}

@test "Configure Old Hoarder" {
  # Run Hook
  run run_hook "test-migrate-old" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]
}

@test "Start Hoarder On Old" {
  run run_hook "test-migrate-old" "start" "$(payload start)"
  [ "$status" -eq 0 ]
}

@test "Insert Service Data" {
  run docker exec "test-migrate-old" bash -c "curl -k -H \"x-auth-token: 123\" https://localhost:7410/blobs/test -d \"data\" 2> /dev/null "
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Start New Container" {
  start_container "test-migrate-new" "192.168.0.4"
}

@test "Configure New Hoarder" {
  run run_hook "test-migrate-new" "configure" "$(payload configure-new)"
  [ "$status" -eq 0 ]
}

@test "Prepare New Import" {
  run run_hook "test-migrate-new" "import-prep" "$(payload import-prep)"
  [ "$status" -eq 0 ]
}

@test "Export Live Data" {
  run run_hook "test-migrate-old" "export-live" "$(payload export-live)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Stop Old Hoarder Service" {
  run run_hook "test-migrate-old" "stop" "$(payload stop)"
  [ "$status" -eq 0 ]
}

@test "Export Final Data" {
  run run_hook "test-migrate-old" "export-final" "$(payload export-final)"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Clean After Import" {
  run run_hook "test-migrate-new" "import-clean" "$(payload import-clean)"
  [ "$status" -eq 0 ]
}

@test "Start New Hoarder Service" {
  run run_hook "test-migrate-new" "start" "$(payload start)"
  [ "$status" -eq 0 ]
}

@test "Verify Data Transfered" {
  run docker exec "test-migrate-new" bash -c "curl -k -H \"x-auth-token: 123\" https://localhost:7410/blobs/test 2> /dev/null"
  [ "$status" -eq 0 ]
  echo "$output"
  [ "$output" = "data" ]
}

@test "Stop Old Container" {
  stop_container "test-migrate-old"
}

@test "Stop New Container" {
  stop_container "test-migrate-new"
}

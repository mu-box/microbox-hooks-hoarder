# source docker helpers
. util/docker.sh

@test "Start Container" {
  start_container "test-single" "192.168.0.2"
}

@test "Configure" {
  # Run Hook
  run run_hook "test-single" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]

  # Verify hoarder configuration
  run docker exec test-single bash -c "[ -f /etc/hoarder/config.yml ]"
  [ "$status" -eq 0 ]

  # Verify narc configuration
  run docker exec test-single bash -c "[ -f /opt/gomicro/etc/narc.conf ]"
  [ "$status" -eq 0 ]
}

@test "Start" {
  # Run hook
  run run_hook "test-single" "start" "$(payload start)"
  [ "$status" -eq 0 ]

  # Verify hoarder running
  run docker exec test-single bash -c "ps aux | grep [h]oarder"
  [ "$status" -eq 0 ]

  # Verify slurp running
  run docker exec test-single bash -c "ps aux | grep [s]lurp"
  [ "$status" -eq 0 ]

  # Verify narc running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 0 ]
}

@test "Verify Hoarder Service" {
  # Verify blob list is empty
  run docker exec test-single bash -c "curl -k -H \"x-auth-token: 123\" https://localhost:7410/blobs 2> /dev/null"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]

  # Add a blob
  run docker exec test-single bash -c "curl -k -H \"x-auth-token: 123\" https://localhost:7410/blobs/test -d \"data\" 2> /dev/null "
  echo "$output"
  [ "$status" -eq 0 ]

  # Verify blob exists
  run docker exec test-single bash -c "curl -k -H \"x-auth-token: 123\" https://localhost:7410/blobs/test 2> /dev/null"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$output" = "data" ]
}

@test "Stop" {
  # Run hook
  run run_hook "test-single" "stop" "$(payload stop)"
  echo "$output"
  [ "$status" -eq 0 ]

  # Run stop a second time, it shouldn't break things
  run run_hook "test-single" "stop" "$(payload stop)"
  echo "$output"
  [ "$status" -eq 0 ]

  # Wait until services shut down
  while docker exec "test-single" bash -c "ps aux | grep [h]oarder"
  do
    sleep 1
  done

  # Verify hoarder is not running
  run docker exec test-single bash -c "ps aux | grep [h]oarder"
  [ "$status" -eq 1 ]

  # Verify narc is not running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]
}

@test "Stop Container" {
  stop_container "test-single"
}

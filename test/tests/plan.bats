# source docker helpers
. util/docker.sh

@test "Start Container" {
  start_container "test-plan" "192.168.0.2"
}

@test "Verify Plan" {
  run run_hook "test-plan" "plan" "$(payload plan)"

  expected=$(cat <<-END
{
	"behaviors": [
		"backupable",
		"migratable"
	]
}
END)

  [ "$output" = "$expected" ]
}

@test "Stop Container" {
  stop_container "test-plan"
}

package two_phase_commit

import "core:c"

MAX_INPUT :: 68

@(export)
two_phase_commit :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	participant_count, timeout_ms := input[0], input[1]
	start_time_ms, current_time_ms := input[2], input[3]
	if participant_count < 1 || participant_count > 64 || length != c.size_t(4 + participant_count) do return -1
	if timeout_ms < 1 do return -1
	if start_time_ms < 0 || current_time_ms < start_time_ms do return -1

	votes_received, commit_votes := i64(0), i64(0)
	has_abort := false
	for i in 0..<int(participant_count) {
		vote := input[4 + i]
		if vote < 0 || vote > 2 do return -1
		if vote == 0 { votes_received += 1; commit_votes += 1 }
		else if vote == 1 { votes_received += 1; has_abort = true }
	}

	state := i64(1)
	if votes_received == participant_count {
		if has_abort { state = 3 } else { state = 2 }
	}
	timed_out := i64(0)
	if current_time_ms - start_time_ms > timeout_ms do timed_out = 1
	return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out)
}

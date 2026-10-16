module two_phase_commit

const max_input = 68

@[export: 'two_phase_commit']
pub fn two_phase_commit(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input { return -1 }
	participant_count := unsafe { input[0] }
	timeout_ms := unsafe { input[1] }
	start_time_ms := unsafe { input[2] }
	current_time_ms := unsafe { input[3] }
	if participant_count < 1 || participant_count > 64 || length != usize(4 + participant_count) { return -1 }
	if timeout_ms < 1 { return -1 }
	if start_time_ms < 0 || current_time_ms < start_time_ms { return -1 }

	mut votes_received := i64(0)
	mut commit_votes := i64(0)
	mut has_abort := false
	for i in 0 .. int(participant_count) {
		vote := unsafe { input[4 + i] }
		if vote < 0 || vote > 2 { return -1 }
		if vote == 0 { votes_received++; commit_votes++ }
		else if vote == 1 { votes_received++; has_abort = true }
	}

	mut state := i64(1)
	if votes_received == participant_count {
		if has_abort { state = 3 } else { state = 2 }
	}
	mut timed_out := i64(0)
	if current_time_ms - start_time_ms > timeout_ms { timed_out = 1 }
	return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out)
}

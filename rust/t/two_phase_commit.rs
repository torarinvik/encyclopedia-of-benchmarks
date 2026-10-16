const MAX_PARTICIPANTS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 68;

#[no_mangle]
pub unsafe extern "C" fn two_phase_commit(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let participant_count = input[0];
    let timeout_ms = input[1];
    let start_time_ms = input[2];
    let current_time_ms = input[3];
    if !(1..=MAX_PARTICIPANTS).contains(&participant_count)
        || length != 4 + participant_count as usize
        || timeout_ms < 1 || start_time_ms < 0
        || current_time_ms < start_time_ms { return -1; }

    let mut votes_received = 0i64;
    let mut commit_votes = 0i64;
    let mut has_abort = false;
    for &vote in &input[4..] {
        if !(0..=2).contains(&vote) { return -1; }
        if vote == 0 { votes_received += 1; commit_votes += 1; }
        else if vote == 1 { votes_received += 1; has_abort = true; }
    }

    let mut state = 1i64;
    if votes_received == participant_count { state = if has_abort { 3 } else { 2 }; }
    let timed_out = if current_time_ms - start_time_ms > timeout_ms { 1 } else { 0 };
    (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out)
}

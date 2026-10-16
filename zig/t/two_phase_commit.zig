const MAX_PARTICIPANTS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 68;

export fn two_phase_commit(input: ?[*]const i64, length: usize) i64 {
    if (length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input orelse return -1;
    const participant_count = values[0];
    const timeout_ms = values[1];
    const start_time_ms = values[2];
    const current_time_ms = values[3];
    if (participant_count < 1 or participant_count > MAX_PARTICIPANTS
        or length != 4 + @as(usize, @intCast(participant_count))
        or timeout_ms < 1 or start_time_ms < 0
        or current_time_ms < start_time_ms) return -1;

    var votes_received: i64 = 0;
    var commit_votes: i64 = 0;
    var has_abort = false;
    const count: usize = @intCast(participant_count);
    for (0..count) |i| {
        const vote = values[4 + i];
        if (vote < 0 or vote > 2) return -1;
        if (vote == 0) { votes_received += 1; commit_votes += 1; }
        else if (vote == 1) { votes_received += 1; has_abort = true; }
    }

    var state: i64 = 1;
    if (votes_received == participant_count) {
        if (has_abort) { state = 3; } else { state = 2; }
    }
    var timed_out: i64 = 0;
    if (current_time_ms - start_time_ms > timeout_ms) timed_out = 1;
    return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out);
}

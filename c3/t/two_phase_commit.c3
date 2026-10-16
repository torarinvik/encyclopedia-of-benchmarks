module two_phase_commit;

const usz MAX_INPUT = 68;
const long MAX_PARTICIPANTS = 64;

fn long two_phase_commit(long* input, usz length) @export("two_phase_commit") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long participant_count = input[0], timeout_ms = input[1];
    long start_time_ms = input[2], current_time_ms = input[3];
    if (participant_count < 1 || participant_count > MAX_PARTICIPANTS
        || length != 4 + (usz)participant_count
        || timeout_ms < 1 || start_time_ms < 0
        || current_time_ms < start_time_ms) return -1;

    long votes_received = 0, commit_votes = 0;
    bool has_abort = false;
    for (usz i = 0; i < (usz)participant_count; i++) {
        long vote = input[4 + i];
        if (vote < 0 || vote > 2) return -1;
        if (vote == 0) { votes_received++; commit_votes++; }
        else if (vote == 1) { votes_received++; has_abort = true; }
    }

    long state = 1;
    if (votes_received == participant_count) state = has_abort ? 3 : 2;
    long timed_out = 0;
    if (current_time_ms - start_time_ms > timeout_ms) timed_out = 1;
    return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out);
}

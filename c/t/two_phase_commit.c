#include <stddef.h>
#include <stdint.h>

#define MAX_PARTICIPANTS 64
#define MAX_INPUT_LENGTH (4 + MAX_PARTICIPANTS)

int64_t two_phase_commit(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t participant_count = input[0];
    const int64_t timeout_ms = input[1];
    const int64_t start_time_ms = input[2];
    const int64_t current_time_ms = input[3];
    if (participant_count < 1 || participant_count > MAX_PARTICIPANTS
        || length != 4 + (size_t)participant_count
        || timeout_ms < 1 || start_time_ms < 0
        || current_time_ms < start_time_ms) return -1;

    int64_t votes_received = 0;
    int64_t commit_votes = 0;
    int has_abort = 0;
    for (size_t i = 0; i < (size_t)participant_count; ++i) {
        const int64_t vote = input[4 + i];
        if (vote < 0 || vote > 2) return -1;
        if (vote == 0) { ++votes_received; ++commit_votes; }
        else if (vote == 1) { ++votes_received; has_abort = 1; }
    }

    int64_t state = 1; /* preparing */
    if (votes_received == participant_count) state = has_abort ? 3 : 2;
    const int64_t timed_out = current_time_ms - start_time_ms > timeout_ms;
    return (((state * 65 + votes_received) * 65 + commit_votes) * 2 + timed_out);
}

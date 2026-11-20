module hofstadter_q_sequence;

import "core:c";

const usz MAX_INDEX = 128;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long hofstadter_q_sequence(long* input, usz length) @export("hofstadter_q_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > (long)MAX_INDEX) return -1;

    usz target = (usz)input[0];
    long[MAX_INDEX + 1] q = zeroed;
    q[1] = 1;
    if (target >= 2) q[2] = 1;
    for (usz n = 3; n <= target; n++) {
        long left = (long)n - q[n - 1];
        long right = (long)n - q[n - 2];
        if (left < 1 || right < 1 || left >= (long)n || right >= (long)n) return -1;
        q[n] = q[(usz)left] + q[(usz)right];
    }
    return q[target];
}

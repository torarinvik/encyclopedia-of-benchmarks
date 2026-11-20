module hofstadter_conway_10000_sequence;

import "core:c";

const usz MAX_INDEX = 8192;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long hofstadter_conway_10000_sequence(long* input, usz length) @export("hofstadter_conway_10000_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 2 || input[0] > (long)MAX_INDEX) return -1;

    usz target = (usz)input[0];
    long[MAX_INDEX + 1] a = zeroed;
    a[1] = 1;
    a[2] = 1;
    for (usz n = 3; n <= target; n++) {
        long previous = a[n - 1];
        long other = (long)n - previous;
        if (previous < 1 || previous >= (long)n || other < 1 || other >= (long)n) return -1;
        a[n] = a[(usz)previous] + a[(usz)other];
    }
    return a[target];
}

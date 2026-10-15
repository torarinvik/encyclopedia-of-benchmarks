module min_number_of_jumps;

const MAX_LENGTH = 64;
const UNREACHABLE = 1000000000000;

fn long min_number_of_jumps(long* values, usz length) @export("min_number_of_jumps") {
    if (values == null || length < 1 || length > MAX_LENGTH) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < 0 || values[i] > MAX_LENGTH) return -1;
    long[MAX_LENGTH] jumps;
    for (usz i = 0; i < MAX_LENGTH; i++) jumps[i] = UNREACHABLE;
    jumps[0] = 0;
    for (usz i = 1; i < length; i++) {
        for (usz j = 0; j < i; j++) {
            if (values[j] + (long)j >= (long)i && jumps[j] + 1 < jumps[i]) jumps[i] = jumps[j] + 1;
        }
    }
    return jumps[length - 1];
}

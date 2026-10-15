module equilibrium_index_in_array;

const MAX_LENGTH = 1024;
const MIN_I32 = -2147483648;
const MAX_I32 = 2147483647;

fn long equilibrium_index_in_array(long* values, usz length) @export("equilibrium_index_in_array") {
    if (values == null || length < 1 || length > MAX_LENGTH + 1) return -2;
    long n = values[0];
    if (n < 0 || n > MAX_LENGTH || length != (usz)n + 1) return -2;
    long total = 0;
    for (usz i = 1; i < length; i++) {
        if (values[i] < MIN_I32 || values[i] > MAX_I32) return -2;
        total += values[i];
    }
    long left = 0;
    for (long i = 0; i < n; i++) {
        total -= values[(usz)i + 1];
        if (left == total) return i;
        left += values[(usz)i + 1];
    }
    return -1;
}

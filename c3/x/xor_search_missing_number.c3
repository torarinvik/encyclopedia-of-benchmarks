module xor_search_missing_number;

const long MAX_N = 255;
const usz MAX_INPUT_LENGTH = 257;

fn long xor_search_missing_number(long* input, usz length) @export("xor_search_missing_number") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > MAX_N || length != (usz)(n_value + 1)) return -1;
    usz n = (usz)n_value;
    long[256] seen = {0};
    long result = n_value;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 1];
        if (value < 0 || value > n_value || seen[(usz)value] != 0) return -1;
        seen[(usz)value] = 1;
        result ^= (long)i ^ value;
    }
    return result;
}

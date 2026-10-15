module max_sum_sliding_window;

const long INVALID_RESULT = (-9223372036854775807L - 1L);
const usz MAX_N = 100000;

fn long max_sum_sliding_window(long* values, usz length) @export("max_sum_sliding_window") {
    if (values == null || length < 3 || length > MAX_N + 2) return INVALID_RESULT;
    long n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > 100000 || k_value < 1 || k_value > n_value ||
        length != (usz)n_value + 2) return INVALID_RESULT;
    usz n = (usz)n_value, k = (usz)k_value;
    long current_sum = 0;
    for (usz i = 0; i < n; i++) {
        long value = values[i + 2];
        if (value < -1000000000 || value > 1000000000) return INVALID_RESULT;
        if (i < k) current_sum += value;
    }
    long maximum_sum = current_sum;
    for (usz i = 0; i < n - k; i++) {
        current_sum = current_sum - values[i + 2] + values[i + k + 2];
        if (current_sum > maximum_sum) maximum_sum = current_sum;
    }
    return maximum_sum;
}

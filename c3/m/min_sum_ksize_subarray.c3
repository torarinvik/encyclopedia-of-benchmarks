module min_sum_ksize_subarray;

const long INVALID_RESULT = (-9223372036854775807L - 1L);

fn long min_sum_ksize_subarray(long* values, usz length) @export("min_sum_ksize_subarray") {
    if (values == null || length < 2 || length > 100002) return INVALID_RESULT;
    long n_value = values[0], k_value = values[1];
    if (n_value < 0 || n_value > 100000 || k_value < 0 || k_value > 100000 ||
        length != (usz)n_value + 2) return INVALID_RESULT;
    usz n = (usz)n_value, k = (usz)k_value;
    for (usz i = 0; i < n; i++)
        if (values[i + 2] < -10000 || values[i + 2] > 10000) return INVALID_RESULT;
    if (k > n) return -1;
    long window_sum = 0;
    for (usz i = 0; i < k; i++) window_sum += values[i + 2];
    long minimum_sum = window_sum;
    for (usz i = k; i < n; i++) {
        window_sum += values[i + 2] - values[i - k + 2];
        if (window_sum < minimum_sum) minimum_sum = window_sum;
    }
    return minimum_sum;
}

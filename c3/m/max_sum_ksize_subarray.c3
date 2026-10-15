module max_sum_ksize_subarray;

// Maximum sum of a fixed-size window; the final packed value is k.
fn long max_sum_ksize_subarray(long* values, usz length) @export("max_sum_ksize_subarray") {
    if (length == 0 || length > 64 || values == null) return -1;
    usz array_length = length - 1;
    long k_value = values[length - 1];
    if (k_value < 0 || (ulong)k_value > array_length) return -1;
    for (usz index = 0; index < array_length; index++)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (k_value == 0) return 0;

    usz k = (usz)k_value;
    long window_sum = 0;
    for (usz index = 0; index < k; index++) window_sum += values[index];
    long maximum_sum = window_sum;
    for (usz index = k; index < array_length; index++) {
        window_sum += values[index] - values[index - k];
        if (window_sum > maximum_sum) maximum_sum = window_sum;
    }
    return maximum_sum;
}

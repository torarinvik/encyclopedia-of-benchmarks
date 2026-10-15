/// Maximum sum of a fixed-size window; the final packed value is k.
export fn max_sum_ksize_subarray(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 64) return -1;
    const array_length = length - 1;
    const k_value = values[array_length];
    if (k_value < 0 or k_value > array_length) return -1;
    for (values[0..array_length]) |value| {
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }
    if (k_value == 0) return 0;

    const k: usize = @intCast(k_value);
    var window_sum: i64 = 0;
    for (values[0..k]) |value| window_sum += value;
    var maximum_sum = window_sum;
    for (k..array_length) |index| {
        window_sum += values[index] - values[index - k];
        maximum_sum = @max(maximum_sum, window_sum);
    }
    return maximum_sum;
}

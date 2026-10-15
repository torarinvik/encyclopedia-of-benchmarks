const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

export fn min_sum_ksize_subarray(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 100002) return INVALID_RESULT;
    const n_value = values[0];
    const k_value = values[1];
    if (n_value < 0 or n_value > 100000 or k_value < 0 or k_value > 100000) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != n + 2) return INVALID_RESULT;
    for (0..n) |i| {
        if (values[i + 2] < -10000 or values[i + 2] > 10000) return INVALID_RESULT;
    }
    if (k > n) return -1;
    var window_sum: i64 = 0;
    for (0..k) |i| window_sum += values[i + 2];
    var minimum_sum = window_sum;
    for (k..n) |i| {
        window_sum += values[i + 2] - values[i - k + 2];
        minimum_sum = @min(minimum_sum, window_sum);
    }
    return minimum_sum;
}

const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

export fn max_sum_sliding_window(values: [*]const i64, length: usize) i64 {
    if (length < 3 or length > 100002) return INVALID_RESULT;
    const n_value = values[0];
    const k_value = values[1];
    if (n_value < 1 or n_value > 100000 or k_value < 1 or k_value > n_value) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != n + 2) return INVALID_RESULT;
    var current_sum: i64 = 0;
    for (0..n) |i| {
        const value = values[i + 2];
        if (value < -1000000000 or value > 1000000000) return INVALID_RESULT;
        if (i < k) current_sum += value;
    }
    var maximum_sum = current_sum;
    for (0..n - k) |i| {
        current_sum = current_sum - values[i + 2] + values[i + k + 2];
        maximum_sum = @max(maximum_sum, current_sum);
    }
    return maximum_sum;
}

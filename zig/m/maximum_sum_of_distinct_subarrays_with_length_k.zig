const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);
const MAX_N: usize = 8192;
const CAPACITY: usize = 16384;

export fn maximum_sum_of_distinct_subarrays_with_length_k(values: [*]const i64, length: usize) i64 {
    if (length < 3 or length > MAX_N + 2) return INVALID_RESULT;
    const n_value = values[0];
    const k_value = values[1];
    if (n_value < 1 or n_value > MAX_N or k_value < 1 or k_value > n_value) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    if (length != n + 2) return INVALID_RESULT;
    var keys: [CAPACITY]i32 = @splat(0);
    var last_plus_one: [CAPACITY]i32 = @splat(0);
    var current_sum: i64 = 0;
    var maximum_sum: i64 = 0;
    var distinct_start: usize = 0;
    for (0..n) |i| {
        const input = values[i + 2];
        if (input < std.math.minInt(i32) or input > std.math.maxInt(i32)) return INVALID_RESULT;
        const value: i32 = @intCast(input);
        if (i < k) current_sum += value
        else {
            current_sum -= values[i - k + 2];
            current_sum += value;
        }
        var slot: usize = @intCast(@mod(input + 2147483648, 16384));
        while (last_plus_one[slot] != 0 and keys[slot] != value) slot = (slot + 1) & (CAPACITY - 1);
        if (last_plus_one[slot] != 0) {
            const previous: usize = @intCast(last_plus_one[slot] - 1);
            if (previous >= distinct_start) distinct_start = previous + 1;
        } else keys[slot] = value;
        last_plus_one[slot] = @intCast(i + 1);
        if (i + 1 >= k) {
            const start = i + 1 - k;
            if (start >= distinct_start and current_sum > maximum_sum) maximum_sum = current_sum;
        }
    }
    return maximum_sum;
}

/// Count unordered partitions of a positive integer using the pinned 2D DP.
export fn integer_partition(m: i64) i64 {
    if (m < 1 or m > 300) return std.math.minInt(i64);
    const stride: usize = 300;
    const input: usize = @intCast(m);
    var memo: [90300]i64 = @splat(0);
    for (0..input + 1) |i| memo[i * stride] = 1;
    for (0..input + 1) |n| {
        for (1..input) |k| {
            const index = n * stride + k;
            memo[index] += memo[index - 1];
            if (n > k) memo[index] += memo[(n - k - 1) * stride + k];
        }
    }
    return memo[input * stride + input - 1];
}

const std = @import("std");

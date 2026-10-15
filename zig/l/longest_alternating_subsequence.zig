const std = @import("std");

/// Return the length of a strict longest alternating subsequence.
const MAX_LENGTH: usize = 512;

export fn longest_alternating_subsequence(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    var rising: [MAX_LENGTH]i64 = @splat(0);
    var falling: [MAX_LENGTH]i64 = @splat(0);
    var result: i64 = 1;
    for (0..length) |index| {
        const value = values[index];
        if (value < @as(i64, std.math.minInt(i32)) or value > @as(i64, std.math.maxInt(i32))) return -1;
        rising[index] = 1;
        falling[index] = 1;
        for (0..index) |previous| {
            const prior = values[previous];
            if (prior < value and rising[index] < falling[previous] + 1) {
                rising[index] = falling[previous] + 1;
            }
            if (prior > value and falling[index] < rising[previous] + 1) {
                falling[index] = rising[previous] + 1;
            }
        }
        result = @max(result, @max(rising[index], falling[index]));
    }
    return result;
}

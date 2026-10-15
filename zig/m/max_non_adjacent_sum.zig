const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

export fn max_non_adjacent_sum(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 100000) return INVALID_RESULT;
    var two_back: i64 = 0;
    var one_back: i64 = 0;
    for (0..length) |i| {
        const value = values[i];
        if (value < 0 or value > 10000) return INVALID_RESULT;
        const take = two_back + value;
        const current = @max(take, one_back);
        two_back = one_back;
        one_back = current;
    }
    return one_back;
}

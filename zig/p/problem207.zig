const std = @import("std");
const INVALID_RESULT: f64 = -1.0e300;
const MIN_PROPORTION: f64 = 1.0e-5;
const MAX_PROPORTION: f64 = 1.0;
const MAX_PARTITIONS: i64 = 5_000_000;

fn isPowerOfTwo(value: i64) bool {
    return value > 0 and (value & (value - 1)) == 0;
}

pub export fn problem207(max_proportion: f64) f64 {
    if (std.math.isNan(max_proportion) or max_proportion < MIN_PROPORTION or max_proportion > MAX_PROPORTION)
        return INVALID_RESULT;
    var partitions: i64 = 0;
    var perfect_partitions: i64 = 0;
    while (partitions < MAX_PARTITIONS) {
        partitions += 1;
        const candidate = partitions * (partitions + 1);
        if (isPowerOfTwo(partitions + 1)) perfect_partitions += 1;
        if (@as(f64, @floatFromInt(perfect_partitions)) / @as(f64, @floatFromInt(partitions)) < max_proportion)
            return @floatFromInt(candidate);
    }
    return INVALID_RESULT;
}

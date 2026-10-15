const MAX_N: i64 = 64;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn weighted_average(packed: [*]const i64, length: usize) f64 {
    if (length < 1 or length > 129) return INVALID_RESULT;
    const n = packed[0];
    if (n < 1 or n > MAX_N or length != @as(usize, @intCast(1 + 2 * n))) return INVALID_RESULT;
    var weighted_sum: i64 = 0;
    var total_weight: i64 = 0;
    for (0..@as(usize, @intCast(n))) |index| {
        const value = packed[1 + index];
        const weight = packed[1 + @as(usize, @intCast(n)) + index];
        if (value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE or
            weight < -MAX_ABS_VALUE or weight > MAX_ABS_VALUE) return INVALID_RESULT;
        weighted_sum += value * weight;
        total_weight += weight;
    }
    if (total_weight == 0) return INVALID_RESULT;
    return @as(f64, @floatFromInt(weighted_sum)) / @as(f64, @floatFromInt(total_weight));
}

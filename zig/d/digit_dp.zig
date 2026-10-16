const MAX_DIGITS: usize = 19;
const MAX_DIGIT_SUM: usize = 171;
const MAX_INPUT_LENGTH: usize = 4;
const MIN_BOUND: i64 = -1;
const MAX_BOUND: i64 = 1_000_000_000_000_000_000;

fn countUpTo(bound_value: i64, target: usize) i64 {
    if (bound_value < 0) return 0;
    var bound = bound_value;
    var digits: [MAX_DIGITS]usize = @splat(0);
    var digit_count: usize = 0;
    while (true) {
        digits[digit_count] = @intCast(@mod(bound, 10));
        digit_count += 1;
        bound = @divTrunc(bound, 10);
        if (bound == 0) break;
    }

    var loose: [MAX_DIGIT_SUM + 1]i64 = @splat(0);
    var tight: [MAX_DIGIT_SUM + 1]i64 = @splat(0);
    tight[0] = 1;
    while (digit_count > 0) {
        digit_count -= 1;
        const limit = digits[digit_count];
        var next_loose: [MAX_DIGIT_SUM + 1]i64 = @splat(0);
        var next_tight: [MAX_DIGIT_SUM + 1]i64 = @splat(0);
        for (0..target + 1) |sum| {
            for (0..10) |digit| {
                if (sum + digit > target) break;
                next_loose[sum + digit] += loose[sum];
            }
            for (0..limit + 1) |digit| {
                if (sum + digit > target) break;
                if (digit == limit) next_tight[sum + digit] += tight[sum]
                else next_loose[sum + digit] += tight[sum];
            }
        }
        loose = next_loose;
        tight = next_tight;
    }
    return loose[target] + tight[target];
}

export fn digit_dp(input: [*c]const i64, length: usize) i64 {
    if (input == null or length > MAX_INPUT_LENGTH or length != 3) return -1;
    const lower = input[0];
    const upper = input[1];
    const target_value = input[2];
    if (lower < MIN_BOUND or lower > MAX_BOUND or upper < MIN_BOUND or upper > MAX_BOUND
        or target_value < std.math.minInt(i32) or target_value > std.math.maxInt(i32)) return -1;
    if (lower > upper or target_value < 0 or target_value > MAX_DIGIT_SUM) return 0;
    const target: usize = @intCast(target_value);
    return countUpTo(upper, target) - countUpTo(lower - 1, target);
}

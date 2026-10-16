const MAX_LIMIT: i64 = 10_000_000;
const MAX_DIGITS: usize = 7;
const MAX_SUM: usize = MAX_DIGITS * 81 + 1;

fn digitSquareSum(input_value: u32) u32 {
    var value = input_value;
    var total: u32 = 0;
    while (value != 0) {
        const digit = value % 10;
        total += digit * digit;
        value /= 10;
    }
    return total;
}

fn reaches89(input_value: u32) bool {
    var value = input_value;
    while (value != 1 and value != 89) value = digitSquareSum(value);
    return value == 89;
}

pub export fn problem92(number: i64) i64 {
    if (number < 0 or number > MAX_LIMIT) return -1;
    var digits = [_]u32{0} ** MAX_DIGITS;
    var reversed = [_]u32{0} ** MAX_DIGITS;
    var digit_count: usize = 0;
    if (number > 1) {
        var remaining: u32 = @intCast(number - 1);
        while (remaining != 0) {
            reversed[digit_count] = @rem(remaining, 10);
            digit_count += 1;
            remaining = @divTrunc(remaining, 10);
        }
        for (0..digit_count) |index| digits[index] = reversed[digit_count - index - 1];
    } else {
        digits[0] = 0;
        digit_count = 1;
    }

    const sum_limit = digit_count * 81 + 1;
    var tight = [_]i64{0} ** MAX_SUM;
    var free_counts = [_]i64{0} ** MAX_SUM;
    var next_tight = [_]i64{0} ** MAX_SUM;
    var next_free = [_]i64{0} ** MAX_SUM;
    tight[0] = 1;
    for (0..digit_count) |position| {
        @memset(&next_tight, 0);
        @memset(&next_free, 0);
        const bound_digit = digits[position];
        for (0..sum_limit) |sum| {
            if (tight[sum] != 0) {
                var digit: u32 = 0;
                while (digit <= bound_digit) : (digit += 1) {
                    const next_sum = sum + @as(usize, @intCast(digit * digit));
                    if (next_sum >= sum_limit) continue;
                    if (digit == bound_digit) {
                        next_tight[next_sum] += tight[sum];
                    } else {
                        next_free[next_sum] += tight[sum];
                    }
                }
            }
            if (free_counts[sum] != 0) {
                for (0..10) |digit| {
                    const next_sum = sum + digit * digit;
                    if (next_sum < sum_limit) next_free[next_sum] += free_counts[sum];
                }
            }
        }
        tight = next_tight;
        free_counts = next_free;
    }
    var result: i64 = 0;
    for (1..sum_limit) |sum| {
        if (reaches89(@intCast(sum))) result += tight[sum] + free_counts[sum];
    }
    return result;
}

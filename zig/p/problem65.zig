const MAX_DIGITS: usize = 256;

pub export fn problem65(max_n: i64) i64 {
    if (max_n < 1 or max_n > 100) return -1;
    var previous = [_]i64{0} ** MAX_DIGITS;
    var current = [_]i64{0} ** MAX_DIGITS;
    var next = [_]i64{0} ** MAX_DIGITS;
    previous[0] = 1;
    current[0] = 2;
    var previous_length: usize = 1;
    var current_length: usize = 1;
    var i: i64 = 2;
    while (i <= max_n) : (i += 1) {
        const coefficient: i64 = if (@mod(i, 3) == 0) @divTrunc(2 * i, 3) else 1;
        var carry: i64 = 0;
        for (0..current_length) |position| {
            const old = if (position < previous_length) previous[position] else 0;
            const total = coefficient * current[position] + old + carry;
            next[position] = @mod(total, 10);
            carry = @divTrunc(total, 10);
        }
        var next_length = current_length;
        while (carry != 0) {
            next[next_length] = @mod(carry, 10);
            next_length += 1;
            carry = @divTrunc(carry, 10);
        }
        for (0..current_length) |position| previous[position] = current[position];
        for (0..next_length) |position| current[position] = next[position];
        previous_length = current_length;
        current_length = next_length;
    }
    var digit_sum: i64 = 0;
    for (0..current_length) |position| digit_sum += current[position];
    return digit_sum;
}

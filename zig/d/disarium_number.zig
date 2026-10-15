/// Sum decimal digits raised to their one-based positions from the left.
export fn disarium_number(number: i64) i64 {
    if (number < 1 or number > 99_999_999) return -1;
    var digits = number;
    var count: i64 = 0;
    while (digits > 0) {
        count += 1;
        digits = @divTrunc(digits, 10);
    }
    var position = count;
    var remaining = number;
    var sum: i64 = 0;
    while (remaining > 0) {
        const digit = @mod(remaining, 10);
        var power: i64 = 1;
        var exponent: i64 = 0;
        while (exponent < position) : (exponent += 1) power *= digit;
        sum += power;
        position -= 1;
        remaining = @divTrunc(remaining, 10);
    }
    return if (sum == number) 1 else 0;
}

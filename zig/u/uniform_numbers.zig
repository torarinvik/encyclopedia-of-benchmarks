/// Count positive repdigits up to the input using the pinned prefix formula.
export fn uniform_numbers(value: i64) i64 {
    if (value < 0 or value > 999999999) return -1;
    var remaining = value;
    var first_digit: i64 = 0;
    var digits: i64 = 0;
    while (true) {
        first_digit = @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
        digits += 1;
        if (remaining == 0) break;
    }
    var repeated: i64 = 0;
    var index: i64 = 0;
    while (index < digits) : (index += 1) repeated = repeated * 10 + first_digit;
    const count = (digits - 1) * 9;
    return count + (if (repeated <= value) first_digit else first_digit - 1);
}

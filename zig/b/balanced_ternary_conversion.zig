const MAX_OUTPUT_BYTES: usize = 41;

export fn balanced_ternary_conversion(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    var reversed: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var digit_count: usize = 0;
    var value = input[0];
    if (value == 0) {
        reversed[digit_count] = '0';
        digit_count += 1;
    }
    while (value != 0) {
        var quotient = @divTrunc(value, 3);
        const remainder = @rem(value, 3);
        var digit: u8 = '1';
        if (remainder == 2) {
            digit = 'Z';
            quotient += 1;
        } else if (remainder == -2) {
            digit = '1';
            quotient -= 1;
        } else if (remainder == -1) {
            digit = 'Z';
        } else if (remainder == 0) {
            digit = '0';
        }
        reversed[digit_count] = digit;
        digit_count += 1;
        value = quotient;
    }
    if (output_opt == null or capacity < digit_count) return -2;
    const output = output_opt.?;
    for (0..digit_count) |index| output[index] = reversed[digit_count - index - 1];
    return @intCast(digit_count);
}

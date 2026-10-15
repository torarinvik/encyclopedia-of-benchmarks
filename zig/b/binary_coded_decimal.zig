/// Write the prefixed four-bit-per-decimal-digit BCD representation.
export fn binary_coded_decimal(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < -2147483648 or value > 2147483647) return -1;
    const normalized: u64 = @intCast(if (value < 0) 0 else value);
    var digits: [10]u8 = undefined;
    var digit_count: usize = 0;
    var remaining = normalized;
    while (remaining > 0) {
        digits[digit_count] = @intCast(remaining % 10);
        digit_count += 1;
        remaining /= 10;
    }
    if (digit_count == 0) {
        digits[0] = 0;
        digit_count = 1;
    }

    const output_length = 2 + digit_count * 4;
    if (output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    var position: usize = 2;
    while (digit_count > 0) {
        digit_count -= 1;
        const digit = digits[digit_count];
        var bit: i32 = 3;
        while (bit >= 0) : (bit -= 1) {
            output[position] = '0' + ((digit >> @intCast(bit)) & 1);
            position += 1;
        }
    }
    return @intCast(output_length);
}

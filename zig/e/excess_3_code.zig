pub export fn excess_3_code(value: i64, output: [*c]u8, output_capacity: usize) i64 {
    var number: u64 = if (value < 0) 0 else @intCast(value);
    var digits: [19]u8 = @splat(0);
    var count: usize = 0;
    while (number > 0) {
        digits[count] = @intCast(number % 10);
        count += 1;
        number /= 10;
    }
    if (count == 0) {
        digits[0] = 0;
        count = 1;
    }
    const output_length = 2 + 4 * count;
    if (output == null or output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    var position: usize = 2;
    while (count > 0) {
        count -= 1;
        const nibble: u8 = digits[count] + 3;
        for (0..4) |index| {
            const bit: u3 = @intCast(3 - index);
            output[position] = if ((nibble & (@as(u8, 1) << bit)) != 0) '1' else '0';
            position += 1;
        }
    }
    return @intCast(output_length);
}

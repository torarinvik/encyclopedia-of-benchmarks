const MAX_DIGITS: usize = 1024;

export fn add_two_numbers(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 2 + 2 * MAX_DIGITS) return -1;
    if (input[0] < 0 or input[0] > MAX_DIGITS or input[1] < 0 or input[1] > MAX_DIGITS) return -1;
    const first_length: usize = @intCast(input[0]);
    const second_length: usize = @intCast(input[1]);
    if (length != first_length + second_length + 2) return -1;
    for (0..first_length + second_length) |index| {
        if (input[index + 2] < 0 or input[index + 2] > 9) return -1;
    }
    const digit_count = @max(first_length, second_length);
    var digits: [MAX_DIGITS + 1]u8 = undefined;
    var result_length: usize = 0;
    var carry: i64 = 0;
    var index: usize = 0;
    while (index < digit_count or carry != 0) : (index += 1) {
        const first: i64 = if (index < first_length) input[index + 2] else 0;
        const second: i64 = if (index < second_length) input[index + 2 + first_length] else 0;
        const sum = first + second + carry;
        digits[result_length] = @intCast(@mod(sum, 10));
        result_length += 1;
        carry = @divTrunc(sum, 10);
    }
    if (output_capacity < result_length) return -2;
    for (0..result_length) |position| output[position] = digits[position];
    return @intCast(result_length);
}

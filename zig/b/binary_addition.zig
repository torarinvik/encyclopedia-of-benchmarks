const MAX_OPERAND_BITS: usize = 2047;

// Add two packed binary strings and return their ASCII representation.
export fn binary_addition(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 2 + 2 * MAX_OPERAND_BITS) return -1;
    if (values[0] < 0 or values[0] > MAX_OPERAND_BITS or
        values[1] < 0 or values[1] > MAX_OPERAND_BITS) return -1;
    const first_length: usize = @intCast(values[0]);
    const second_length: usize = @intCast(values[1]);
    if (length != first_length + second_length + 2) return -1;
    for (0..first_length + second_length) |index| {
        if (values[index + 2] < 0 or values[index + 2] > 1) return -1;
    }
    const width = @max(first_length, second_length);
    if (width == 0) return 0;
    var reversed: [MAX_OPERAND_BITS + 1]u8 = undefined;
    var result_length: usize = 0;
    var carry: i64 = 0;
    for (0..width) |offset| {
        const first: i64 = if (offset < first_length) values[2 + first_length - 1 - offset] else 0;
        const second: i64 = if (offset < second_length)
            values[2 + first_length + second_length - 1 - offset]
        else
            0;
        const sum = first + second + carry;
        reversed[result_length] = '0' + @as(u8, @intCast(@mod(sum, 2)));
        result_length += 1;
        carry = @divTrunc(sum, 2);
    }
    if (carry != 0) {
        reversed[result_length] = '1';
        result_length += 1;
    }
    if (output_capacity < result_length or output == null) return -2;
    for (0..result_length) |index| output[index] = reversed[result_length - 1 - index];
    return @intCast(result_length);
}

const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const MAX_DIGITS: usize = 64;

export fn large_number_add(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const left_length_value = values[0];
    const right_length_value = values[1];
    if (left_length_value < 1 or left_length_value > 64 or
        right_length_value < 1 or right_length_value > 64) return -1;
    const left_length: usize = @intCast(left_length_value);
    const right_length: usize = @intCast(right_length_value);
    if (input_length != 2 + left_length + right_length) return -1;

    var left = [_]u8{0} ** MAX_DIGITS;
    var right = [_]u8{0} ** MAX_DIGITS;
    for (0..left_length) |index| {
        const digit = values[2 + index];
        if (digit < 48 or digit > 57 or (index == 0 and left_length > 1 and digit == 48)) return -1;
        left[left_length - index - 1] = @intCast(digit - 48);
    }
    for (0..right_length) |index| {
        const digit = values[2 + left_length + index];
        if (digit < 48 or digit > 57 or (index == 0 and right_length > 1 and digit == 48)) return -1;
        right[right_length - index - 1] = @intCast(digit - 48);
    }

    var sum = [_]u8{0} ** (MAX_DIGITS + 1);
    var sum_length: usize = 0;
    var carry: u8 = 0;
    while (sum_length < @max(left_length, right_length) or carry != 0) {
        var total = carry;
        if (sum_length < right_length) total += right[sum_length];
        if (sum_length < left_length) total += left[sum_length];
        sum[sum_length] = total % 10;
        carry = total / 10;
        sum_length += 1;
    }
    var staged = [_]u8{0} ** (MAX_DIGITS + 1);
    for (0..sum_length) |index| staged[index] = '0' + sum[sum_length - index - 1];
    const out = output orelse return -2;
    if (output_capacity < sum_length) return -2;
    for (0..sum_length) |index| out[index] = staged[index];
    return @intCast(sum_length);
}

export fn big_integer_multiply(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 66) return -1;
    const left_value = input[0];
    const right_value = input[1];
    if (left_value < 1 or left_value > 32 or right_value < 1 or right_value > 32) return -1;
    const left_length: usize = @intCast(left_value);
    const right_length: usize = @intCast(right_value);
    if (length != 2 + left_length + right_length) return -1;
    const left = input + 2;
    const right = left + left_length;
    for (0..left_length) |index| {
        if (left[index] < 48 or left[index] > 57) return -1;
    }
    for (0..right_length) |index| {
        if (right[index] < 48 or right[index] > 57) return -1;
    }
    if ((left_length > 1 and left[0] == 48) or (right_length > 1 and right[0] == 48)) return -1;

    var product = [_]u16{0} ** 64;
    const product_size = left_length + right_length;
    const is_zero = (left_length == 1 and left[0] == 48) or
        (right_length == 1 and right[0] == 48);
    if (!is_zero) {
        for (0..left_length) |i| {
            for (0..right_length) |j| {
                const position = i + j;
                const multiplication: u16 = @intCast(
                    (left[left_length - i - 1] - 48) * (right[right_length - j - 1] - 48));
                product[position + 1] += (product[position] + multiplication) / 10;
                product[position] = (product[position] + multiplication) % 10;
            }
        }
    }
    const effective_size = if (is_zero) 1 else if (product[product_size - 1] == 0)
        product_size - 1 else product_size;
    if (output == null or capacity < effective_size) return -2;
    if (is_zero) {
        output[0] = '0';
    } else {
        for (0..effective_size) |index|
            output[index] = @intCast(48 + product[effective_size - index - 1]);
    }
    return @intCast(effective_size);
}

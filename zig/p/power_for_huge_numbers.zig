const max_output_bytes: usize = 513;

export fn power_for_huge_numbers(input: [*c]const i64, length: usize,
                                 output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const base = input[0];
    const exponent = input[1];
    if (base < 1 or base > 10000 or exponent < 0 or exponent > 128) return -1;

    var digits: [max_output_bytes]u8 = undefined;
    digits[0] = 1;
    var digit_count: usize = 1;
    var power: i64 = 0;
    while (power < exponent) : (power += 1) {
        var carry: u32 = 0;
        for (0..digit_count) |i| {
            const product = @as(u32, digits[i]) * @as(u32, @intCast(base)) + carry;
            digits[i] = @intCast(product % 10);
            carry = product / 10;
        }
        while (carry != 0) {
            if (digit_count == max_output_bytes) return -1;
            digits[digit_count] = @intCast(carry % 10);
            digit_count += 1;
            carry /= 10;
        }
    }
    if (output == null or capacity < digit_count) return -2;
    for (0..digit_count) |i| output[i] = @intCast('0' + digits[digit_count - 1 - i]);
    return @intCast(digit_count);
}

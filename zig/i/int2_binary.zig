/// Encode the C# uint overload as exactly 32 ASCII binary digits.
export fn int2_binary(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 0 or value > 4294967295) return -1;
    if (output_capacity < 32) return -2;

    var remaining: u32 = @intCast(value);
    var most_significant_bit: u32 = 0x80000000;
    for (0..32) |i| {
        if (remaining >= most_significant_bit) {
            output[i] = '1';
            remaining -= most_significant_bit;
        } else {
            output[i] = '0';
        }
        most_significant_bit /= 2;
    }
    return 32;
}

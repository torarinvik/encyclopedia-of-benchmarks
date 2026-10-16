const MAX_VALUE: i64 = 1_073_741_823;

export fn non_repeating_element(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 64 or length % 2 != 0) return -1;
    var xor_result: i32 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > MAX_VALUE) return -1;
        xor_result ^= @intCast(value);
    }
    const rightmost_set_bit = xor_result & -xor_result;
    var num1: i32 = 0;
    var num2: i32 = 0;
    for (0..length) |index| {
        const value: i32 = @intCast(values[index]);
        if ((value & rightmost_set_bit) != 0) num1 ^= value else num2 ^= value;
    }
    return (@as(i64, num1) << 32) | @as(i64, @intCast(@as(u32, @bitCast(num2))));
}

/// Return whether two signed 32-bit values differ in exactly one bit.
export fn one_bit_difference(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const left = input[0];
    const right = input[1];
    if (left < -2147483648 or left > 2147483647 or right < -2147483648 or right > 2147483647) return -1;
    const difference: u32 = @as(u32, @bitCast(@as(i32, @intCast(left)))) ^ @as(u32, @bitCast(@as(i32, @intCast(right))));
    return @intFromBool(difference != 0 and (difference & (difference - 1)) == 0);
}

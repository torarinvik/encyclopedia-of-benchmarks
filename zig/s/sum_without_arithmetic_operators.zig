/// Java int addition by recursive XOR and shifted carry, modulo 2^32.
fn addRecursive(a: u32, b: u32) u32 {
    if (b == 0) return a;
    return addRecursive(a ^ b, (a & b) << 1);
}

export fn sum_without_arithmetic_operators(a: i64, b: i64) i64 {
    if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647) return -2147483649;
    const bits = addRecursive(@bitCast(@as(i32, @intCast(a))), @bitCast(@as(i32, @intCast(b))));
    return @as(i64, @as(i32, @bitCast(bits)));
}

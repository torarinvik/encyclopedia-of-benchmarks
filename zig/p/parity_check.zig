export fn parity_check(value: i64) i64 {
    if (value < -2147483648 or value > 2147483647) return -1;
    var number: i32 = @intCast(value);
    var parity: i32 = 0;
    while (number > 0) {
        parity ^= number & 1;
        number >>= 1;
    }
    return if (parity == 0) 1 else 0;
}

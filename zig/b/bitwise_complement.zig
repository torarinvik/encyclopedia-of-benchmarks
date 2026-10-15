/// Complement only the significant binary digits of a nonnegative integer.
pub export fn bitwise_complement(n: i64) i64 {
    if (n < 0 or n > 2_147_483_647) return -1;
    if (n == 0) return 1;
    var value: u64 = @intCast(n);
    var mask: u64 = 0;
    while (value != 0) {
        mask = (mask << 1) | 1;
        value >>= 1;
    }
    return n ^ @as(i64, @intCast(mask));
}

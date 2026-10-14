/// Portable LCM with overflow checked after dividing by the GCD.
export fn lcm(left: u64, right: u64) i64 {
    if (left == 0 or right == 0) return 0;
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = a % b;
        a = b;
        b = remainder;
    }
    const reduced = left / a;
    const max_result: u64 = 9223372036854775807;
    if (reduced > max_result / right) return -1;
    return @intCast(reduced * right);
}

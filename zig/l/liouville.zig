/// Go's distinct-factor Liouville variant: (-1) raised to omega(n).
export fn liouville(input: i64) i64 {
    if (input < 1 or input > 2147483647) return -2;
    var remaining: u64 = @intCast(input);
    var sign: i64 = 1;
    var factor: u64 = 2;
    while (factor <= remaining / factor) {
        if (remaining % factor == 0) {
            sign = -sign;
            while (remaining % factor == 0) {
                remaining /= factor;
            }
        }
        if (factor == 2) { factor = 3; } else { factor += 2; }
    }
    if (remaining > 1) sign = -sign;
    return sign;
}

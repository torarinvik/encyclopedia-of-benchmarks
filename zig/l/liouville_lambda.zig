/// Liouville's function: (-1) raised to the number of prime factors with multiplicity.
export fn liouville_lambda(input: i64) i64 {
    if (input < 1 or input > 2147483647) return -1;
    var remaining: u64 = @intCast(input);
    var sign: i64 = 1;
    var factor: u64 = 2;
    while (factor <= remaining / factor) {
        while (remaining % factor == 0) {
            remaining /= factor;
            sign = -sign;
        }
        if (factor == 2) { factor = 3; } else { factor += 2; }
    }
    if (remaining > 1) sign = -sign;
    return sign;
}

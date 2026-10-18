const INVALID_RESULT: i64 = -1;
const FACTOR_BASE: i64 = 65_536;
const MAX_PACKED_LENGTH: usize = 21;

fn gcdI64(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) { const remainder = @mod(a, b); a = b; b = remainder; }
    return a;
}

fn powerModI64(base: i64, exponent_input: i64, modulus: i64) i64 {
    var exponent = exponent_input;
    var result: i64 = 1;
    var power = @mod(base, modulus);
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * power, modulus);
        power = @mod(power * power, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn rsa_factorization(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 4 or length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const d = values[0];
    const e = values[1];
    const modulus = values[2];
    const attempts = values[3];
    if (d < 1 or d > 1_000_000 or e < 1 or e > 1_000_000 or modulus < 3 or modulus > 65_535 or
        @mod(modulus, 2) == 0 or attempts < 1 or attempts > 16 or length != @as(usize, @intCast(4 + attempts))) return INVALID_RESULT;
    const k = d * e - 1;
    if (k <= 0 or @mod(k, 2) != 0) return INVALID_RESULT;
    const attempt_count: usize = @intCast(attempts);
    for (0..attempt_count) |i| { const base = values[4 + i]; if (base < 2 or base > modulus - 1) return INVALID_RESULT; }
    for (0..attempt_count) |i| {
        const base = values[4 + i];
        var t = k;
        while (@mod(t, 2) == 0) {
            t = @divTrunc(t, 2);
            const x = powerModI64(base, t, modulus);
            const factor = gcdI64(x - 1, modulus);
            if (x > 1 and factor > 1) {
                const other = @divTrunc(modulus, factor);
                const p = @min(factor, other);
                const q = @max(factor, other);
                return p * FACTOR_BASE + q;
            }
        }
    }
    return INVALID_RESULT;
}

const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn inverse(a: i64, m: i64) i64 {
    var old_r = a;
    var r = m;
    var old_s: i64 = 1;
    var s: i64 = 0;
    while (r != 0) {
        const quotient = @divTrunc(old_r, r);
        const next_r = old_r - quotient * r;
        const next_s = old_s - quotient * s;
        old_r = r;
        r = next_r;
        old_s = s;
        s = next_s;
    }
    return if (old_r == 1) @mod(old_s + m, m) else -1;
}

/// Compute the pinned factorial-table nCr modulo p contract.
export fn ncr_modulo_p(values: [*]const i64, length: usize) i64 {
    if (length != 4) return INVALID_RESULT;
    const size = values[0];
    const p = values[1];
    const n = values[2];
    const r = values[3];
    if (size < 0 or size > 64 or p < 2 or p > 1009 or n < 0 or n > size or r < 0 or r > 64) return INVALID_RESULT;

    var fac = [_]i64{0} ** 65;
    fac[0] = 1;
    var i: i64 = 1;
    while (i <= size) : (i += 1) fac[@intCast(i)] = @mod(fac[@intCast(i - 1)] * i, p);
    if (r > n) return 0;
    if (r == 1) return @mod(n, p);
    if (r == 0 or r == n) return 1;
    const denominator = @mod(fac[@intCast(r)] * fac[@intCast(n - r)], p);
    const denominator_inv = inverse(denominator, p);
    if (denominator_inv < 0) return -1;
    return @mod(fac[@intCast(n)] * denominator_inv, p);
}

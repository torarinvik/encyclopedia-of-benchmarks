const modulus: i64 = 1000000007;

fn powerMod(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

export fn turnstile_one_sparse_fingerprint_recovery(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 260) return -1;
    const input = input_opt.?;
    const n = input[0];
    const q = input[1];
    const base = input[2];
    if (n < 1 or n > 64 or q < 0 or q > 128 or base < 1 or base >= modulus) return -1;
    if (length != @as(usize, @intCast(3 + 2 * q))) return -1;
    var mass: i64 = 0;
    var weighted: i64 = 0;
    var fingerprint: i64 = 0;
    for (0..@as(usize, @intCast(q))) |i| {
        const index = input[3 + 2 * i];
        const delta = input[4 + 2 * i];
        if (index < 0 or index >= n or delta < -1000 or delta > 1000) return -1;
        mass += delta;
        weighted += delta * index;
        fingerprint = @mod(fingerprint + delta * powerMod(base, index), modulus);
    }
    if (mass == 0 or @rem(weighted, mass) != 0) return 0;
    const index = @divTrunc(weighted, mass);
    if (index < 0 or index >= n) return 0;
    const expected = @mod(mass * powerMod(base, index), modulus);
    return if (fingerprint == expected) index + 1 else 0;
}

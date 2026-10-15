fn modPow(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = @mod(base_value, modulus);
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

fn legendreSymbol(residue: i64, prime: i64) i64 {
    const symbol = modPow(@mod(residue, prime), @divTrunc(prime - 1, 2), prime);
    return if (symbol == prime - 1) -1 else symbol;
}

export fn tonelli_shanks(packed: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const residue = packed[0];
    const prime = packed[1];
    if (prime <= 2 or @mod(prime, 2) == 0 or prime > 1_000_003 or residue < 0 or residue >= prime) return -1;
    if (residue == 0) return 0;
    if (legendreSymbol(residue, prime) != 1) return -1;
    if (@mod(prime, 4) == 3) {
        const root = modPow(residue, @divTrunc(prime + 1, 4), prime);
        return @min(root, prime - root);
    }
    var q = prime - 1;
    var s: i64 = 0;
    while (@mod(q, 2) == 0) {
        q = @divTrunc(q, 2);
        s += 1;
    }
    var non_residue: i64 = 2;
    while (legendreSymbol(non_residue, prime) != -1) non_residue += 1;
    var c = modPow(non_residue, q, prime);
    var r = modPow(residue, @divTrunc(q + 1, 2), prime);
    var t = modPow(residue, q, prime);
    var remaining_s = s;
    while (t != 1) {
        var test_power = t;
        var least_i: i64 = 0;
        var candidate_i: i64 = 1;
        while (candidate_i < remaining_s) : (candidate_i += 1) {
            test_power = modPow(test_power, 2, prime);
            if (test_power == 1) {
                least_i = candidate_i;
                break;
            }
        }
        if (least_i == 0) return -1;
        const exponent: u6 = @intCast(remaining_s - least_i - 1);
        const b = modPow(c, @as(i64, 1) << exponent, prime);
        r = @mod(r * b, prime);
        c = @mod(b * b, prime);
        t = @mod(t * c, prime);
        remaining_s = least_i;
    }
    return @min(r, prime - r);
}

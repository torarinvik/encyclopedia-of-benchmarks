const MAX_PRIME: i64 = 1_000_003;

const Pair = struct {
    real: i64,
    radical: i64,
};

fn modularPower(base_value: i64, exponent_value: i64, prime: i64) i64 {
    var result: i64 = 1;
    var base = @mod(base_value, prime);
    var exponent = exponent_value;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, prime);
        exponent = @divTrunc(exponent, 2);
        if (exponent > 0) base = @rem(base * base, prime);
    }
    return result;
}

fn legendre(value: i64, prime: i64) i64 {
    const symbol = modularPower(@mod(value, prime), @divTrunc(prime - 1, 2), prime);
    return if (symbol == prime - 1) -1 else symbol;
}

fn multiply(left: Pair, right: Pair, radicand: i64, prime: i64) Pair {
    return .{
        .real = @rem(left.real * right.real + radicand * left.radical * right.radical, prime),
        .radical = @rem(left.real * right.radical + left.radical * right.real, prime),
    };
}

fn pairPower(base: Pair, exponent_value: i64, radicand: i64, prime: i64) Pair {
    var result = Pair{ .real = 1, .radical = 0 };
    var factor = base;
    var exponent = exponent_value;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = multiply(result, factor, radicand, prime);
        exponent = @divTrunc(exponent, 2);
        if (exponent > 0) factor = multiply(factor, factor, radicand, prime);
    }
    return result;
}

export fn cipolla_modular_square_root(packed_opt: ?[*]const i64, length: usize) i64 {
    if (packed_opt == null or length != 2) return -1;
    const packed = packed_opt.?;
    const residue = packed[0];
    const prime = packed[1];
    if (prime < 3 or prime > MAX_PRIME or @rem(prime, 2) == 0 or residue < 0 or residue >= prime)
        return -1;
    if (residue == 0) return 0;
    if (legendre(residue, prime) != 1) return -1;

    var parameter: i64 = 0;
    var radicand: i64 = 0;
    while (parameter < prime) : (parameter += 1) {
        radicand = @mod(parameter * parameter - residue, prime);
        if (legendre(radicand, prime) == -1) break;
    }
    if (parameter == prime) return -1;

    const result = pairPower(.{ .real = parameter, .radical = 1 }, @divTrunc(prime + 1, 2), radicand, prime);
    return if (result.real < prime - result.real) result.real else prime - result.real;
}

const modulus: i64 = 998244353;
const max_n: usize = 64;
const max_input: usize = 66;

fn modPower(base_value: i64, exponent_value: i64) i64 {
    var base = base_value % modulus;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn modSquareRoot(value: i64) i64 {
    if (value == 0) return 0;
    if (modPower(value, @divTrunc(modulus - 1, 2)) != 1) return -1;
    var odd_part = modulus - 1;
    var twos: usize = 0;
    while (@mod(odd_part, 2) == 0) { odd_part = @divTrunc(odd_part, 2); twos += 1; }
    var non_residue: i64 = 2;
    while (modPower(non_residue, @divTrunc(modulus - 1, 2)) != modulus - 1) non_residue += 1;
    var c = modPower(non_residue, odd_part);
    var root = modPower(value, @divTrunc(odd_part + 1, 2));
    var remainder = modPower(value, odd_part);
    var order = twos;
    while (remainder != 1) {
        var index: usize = 1;
        var probe = @mod(remainder * remainder, modulus);
        while (index < order and probe != 1) { probe = @mod(probe * probe, modulus); index += 1; }
        if (index >= order or probe != 1) return -1;
        var exponent: i64 = 1;
        var bit: usize = 0;
        while (bit < order - index - 1) : (bit += 1) exponent *= 2;
        const factor = modPower(c, exponent);
        root = @mod(root * factor, modulus);
        const factor_squared = @mod(factor * factor, modulus);
        remainder = @mod(remainder * factor_squared, modulus);
        c = factor_squared;
        order = index;
    }
    return if (root < modulus - root) root else modulus - root;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn sqrt_of_formal_power_series(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var result: [max_n]i64 = @splat(0);
    var valuation: usize = 0;
    while (valuation < n and input[valuation + 1] == 0) : (valuation += 1) {}
    if (valuation == n) {
        const output = output_opt.?;
        for (0..n) |i| storeLe(output, 8 * i, 0);
        return @intCast(bytes);
    }
    if (valuation % 2 != 0) { storeLe(output_opt.?, 0, -1); return 8; }
    const shift = valuation / 2;
    const leading_root = modSquareRoot(input[valuation + 1]);
    if (leading_root < 0) { storeLe(output_opt.?, 0, -1); return 8; }
    const inverse_twice_root = modPower(@mod(2 * leading_root, modulus), modulus - 2);
    const width = n - valuation;
    result[shift] = leading_root;
    for (1..width) |degree| {
        var cross_terms: i64 = 0;
        for (1..degree) |i| cross_terms = @mod(cross_terms + result[shift + i] * result[shift + degree - i], modulus);
        var delta = @mod(input[valuation + degree + 1] - cross_terms, modulus);
        if (delta < 0) delta += modulus;
        result[shift + degree] = @mod(delta * inverse_twice_root, modulus);
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, result[i]);
    return @intCast(bytes);
}

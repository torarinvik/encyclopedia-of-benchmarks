const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 11;
const Points = [MAX_N]i64;
const Differences = [MAX_N]i64;
const NewtonCoefficients = [MAX_N]i64;
const ResultCoefficients = [MAX_N]i64;
const BasisCoefficients = [MAX_N + 1]i64;

fn normalize(value: i64) i64 {
    const reduced = @rem(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn powerMod(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn polynomial_interpolation_on_geometric_sequence(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    const a = input[1];
    const r = input[2];
    if (length != 3 + n or a < 0 or a >= MODULUS or r < 0 or r >= MODULUS) return -1;

    var points: Points = @splat(0);
    var differences: Differences = @splat(0);
    var newton: NewtonCoefficients = @splat(0);
    var point = a;
    for (0..n) |i| {
        points[i] = point;
        differences[i] = input[3 + i];
        if (differences[i] < 0 or differences[i] >= MODULUS) return -1;
        for (0..i) |j| if (points[i] == points[j]) return -1;
        point = @rem(point * r, MODULUS);
    }

    const bytes = 8 * n;
    if (output_opt == null or output_capacity < bytes) return -2;
    if (n == 0) return 0;
    newton[0] = differences[0];
    for (1..n) |order| {
        const r_order = powerMod(r, @intCast(order));
        var end = n;
        while (end > order) {
            end -= 1;
            const r_factor = powerMod(r, @intCast(end - order));
            var denominator = @rem(a * r_factor, MODULUS);
            denominator = @rem(denominator * (r_order - 1), MODULUS);
            const inverse = powerMod(normalize(denominator), MODULUS - 2);
            differences[end] = normalize(@rem((differences[end] - differences[end - 1]) * inverse, MODULUS));
        }
        newton[order] = differences[order];
    }

    var coefficients: ResultCoefficients = @splat(0);
    var basis: BasisCoefficients = @splat(0);
    basis[0] = 1;
    var degree: usize = 0;
    for (0..n) |order| {
        for (0..degree + 1) |k| {
            coefficients[k] = @rem(coefficients[k] + newton[order] * basis[k], MODULUS);
        }
        if (order + 1 == n) break;
        var expanded: BasisCoefficients = @splat(0);
        for (0..degree + 1) |k| {
            expanded[k] = normalize(expanded[k] - basis[k] * points[order]);
            expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
        }
        for (0..degree + 2) |k| basis[k] = expanded[k];
        degree += 1;
    }
    const output = output_opt.?;
    for (0..n) |i| storeLe(output, 8 * i, coefficients[i]);
    return @intCast(bytes);
}

const MODULUS: i64 = 998_244_353;
const MAX_LENGTH: usize = 6;
const MAX_INPUT: usize = 14;
const CAPACITY: usize = 16;
const Poly = [CAPACITY]i64;

const Division = struct {
    quotient: Poly,
    quotient_length: usize,
    remainder: Poly,
    remainder_length: usize,
};

fn powerMod(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn trim(poly: *const Poly, length_input: usize) usize {
    var length = length_input;
    while (length > 0 and poly[length - 1] == 0) : (length -= 1) {}
    return length;
}

fn dividePoly(dividend: *const Poly, dividend_length: usize, divisor: *const Poly, divisor_length: usize) Division {
    var quotient: Poly = @splat(0);
    var remainder = dividend.*;
    var remainder_length = trim(&remainder, dividend_length);
    if (remainder_length >= divisor_length) {
        const inverse_lead = powerMod(divisor[divisor_length - 1], MODULUS - 2);
        while (remainder_length >= divisor_length) {
            const shift = remainder_length - divisor_length;
            const factor = @rem(remainder[remainder_length - 1] * inverse_lead, MODULUS);
            quotient[shift] = factor;
            for (0..divisor_length) |j| {
                var value = @rem(remainder[shift + j] - factor * divisor[j], MODULUS);
                if (value < 0) value += MODULUS;
                remainder[shift + j] = value;
            }
            remainder_length = trim(&remainder, remainder_length);
        }
    }
    const quotient_bound = if (dividend_length >= divisor_length) dividend_length - divisor_length + 1 else 0;
    const quotient_length = trim(&quotient, quotient_bound);
    return .{ .quotient = quotient, .quotient_length = quotient_length,
        .remainder = remainder, .remainder_length = remainder_length };
}

fn multiply(left: *const Poly, left_length: usize, right: *const Poly, right_length: usize) Division {
    var product: Poly = @splat(0);
    if (left_length == 0 or right_length == 0) {
        return .{ .quotient = product, .quotient_length = 0, .remainder = product, .remainder_length = 0 };
    }
    for (0..left_length) |i| {
        for (0..right_length) |j| {
            if (i + j < CAPACITY) product[i + j] = @rem(product[i + j] + left[i] * right[j], MODULUS);
        }
    }
    const bound = @min(CAPACITY, left_length + right_length - 1);
    const product_length = trim(&product, bound);
    return .{ .quotient = product, .quotient_length = product_length,
        .remainder = product, .remainder_length = product_length };
}

fn subtract(left: *const Poly, left_length: usize, right: *const Poly, right_length: usize) Division {
    var difference: Poly = @splat(0);
    const bound = @max(left_length, right_length);
    for (0..bound) |i| {
        const a = if (i < left_length) left[i] else 0;
        const b = if (i < right_length) right[i] else 0;
        difference[i] = @rem(a - b + MODULUS, MODULUS);
    }
    const difference_length = trim(&difference, bound);
    return .{ .quotient = difference, .quotient_length = difference_length,
        .remainder = difference, .remainder_length = difference_length };
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn inv_of_polynomials(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_LENGTH))
            or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_LENGTH))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    var f: Poly = @splat(0);
    var g: Poly = @splat(0);
    for (0..n) |i| {
        f[i] = input[2 + i];
        if (f[i] < 0 or f[i] >= MODULUS) return -1;
    }
    for (0..m) |i| {
        g[i] = input[2 + n + i];
        if (g[i] < 0 or g[i] >= MODULUS) return -1;
    }
    if (f[n - 1] == 0 or g[m - 1] == 0) return -1;

    var inverse: Poly = @splat(0);
    var inverse_length: usize = 0;
    if (m > 1) {
        const initial = dividePoly(&f, n, &g, m);
        var r0 = g;
        var r0_length = m;
        var r1 = initial.remainder;
        var r1_length = initial.remainder_length;
        var s0: Poly = @splat(0);
        var s0_length: usize = 0;
        var s1: Poly = @splat(0);
        s1[0] = 1;
        var s1_length: usize = 1;
        while (r1_length > 0) {
            const division = dividePoly(&r0, r0_length, &r1, r1_length);
            const product = multiply(&division.quotient, division.quotient_length, &s1, s1_length);
            const next_s = subtract(&s0, s0_length, &product.quotient, product.quotient_length);
            r0 = r1;
            r0_length = r1_length;
            r1 = division.remainder;
            r1_length = division.remainder_length;
            s0 = s1;
            s0_length = s1_length;
            s1 = next_s.quotient;
            s1_length = next_s.quotient_length;
        }
        if (r0_length != 1) return -1;
        const scale = powerMod(r0[0], MODULUS - 2);
        for (0..s0_length) |i| inverse[i] = @rem(s0[i] * scale, MODULUS);
        inverse_length = trim(&inverse, s0_length);
    }

    const bytes = 8 * inverse_length;
    if (output_opt == null or output_capacity < bytes) return -2;
    for (0..inverse_length) |i| storeLe(output_opt.?, 8 * i, inverse[i]);
    return @intCast(bytes);
}

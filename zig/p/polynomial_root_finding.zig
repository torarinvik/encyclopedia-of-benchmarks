const MODULUS: i64 = 998_244_353;
const PRNG_MODULUS: i64 = 2_147_483_647;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 10;
const MAX_PRODUCT: usize = 17;

const Polynomial = struct {
    c: [MAX_PRODUCT]i64 = [_]i64{0} ** MAX_PRODUCT,
    degree: i64 = -1,
};

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

fn trim(poly: *Polynomial) void {
    while (poly.degree >= 0 and poly.c[@intCast(poly.degree)] == 0) poly.degree -= 1;
}

fn polyMod(value_input: Polynomial, divisor: *const Polynomial) Polynomial {
    if (divisor.degree <= 0 or value_input.degree < 0) return Polynomial{};
    var value = value_input;
    const inverse = powerMod(divisor.c[@intCast(divisor.degree)], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        const shift: usize = @intCast(value.degree - divisor.degree);
        const factor = @rem(value.c[@intCast(value.degree)] * inverse, MODULUS);
        var i: usize = 0;
        while (i <= @as(usize, @intCast(divisor.degree))) : (i += 1) {
            value.c[shift + i] = normalize(value.c[shift + i] - factor * divisor.c[i]);
        }
        trim(&value);
    }
    return value;
}

fn multiplyMod(left: *const Polynomial, right: *const Polynomial, modulus_poly: *const Polynomial) Polynomial {
    if (left.degree < 0 or right.degree < 0) return Polynomial{};
    var product = [_]i64{0} ** MAX_PRODUCT;
    var i: usize = 0;
    while (i <= @as(usize, @intCast(left.degree))) : (i += 1) {
        var j: usize = 0;
        while (j <= @as(usize, @intCast(right.degree))) : (j += 1) {
            product[i + j] = @rem(product[i + j] + left.c[i] * right.c[j], MODULUS);
        }
    }
    var expanded = Polynomial{ .c = product, .degree = left.degree + right.degree };
    trim(&expanded);
    return polyMod(expanded, modulus_poly);
}

fn polynomialPowerMod(base_input: Polynomial, exponent_input: i64, modulus_poly: *const Polynomial) Polynomial {
    var result = Polynomial{};
    result.c[0] = 1;
    result.degree = 0;
    var base = polyMod(base_input, modulus_poly);
    var exponent = exponent_input;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) result = multiplyMod(&result, &base, modulus_poly);
        base = multiplyMod(&base, &base, modulus_poly);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn polynomialGcd(left_input: Polynomial, right_input: Polynomial) Polynomial {
    var left = left_input;
    var right = right_input;
    while (right.degree >= 0) {
        const remainder = polyMod(left, &right);
        left = right;
        right = remainder;
    }
    if (left.degree < 0) return left;
    const inverse = powerMod(left.c[@intCast(left.degree)], MODULUS - 2);
    var i: usize = 0;
    while (i <= @as(usize, @intCast(left.degree))) : (i += 1) left.c[i] = @rem(left.c[i] * inverse, MODULUS);
    return left;
}

fn divideExact(value_input: Polynomial, divisor: *const Polynomial) Polynomial {
    var value = value_input;
    var quotient = Polynomial{};
    quotient.degree = value.degree - divisor.degree;
    if (quotient.degree < 0) return Polynomial{};
    const inverse = powerMod(divisor.c[@intCast(divisor.degree)], MODULUS - 2);
    while (value.degree >= divisor.degree) {
        const shift: usize = @intCast(value.degree - divisor.degree);
        const factor = @rem(value.c[@intCast(value.degree)] * inverse, MODULUS);
        quotient.c[shift] = factor;
        var i: usize = 0;
        while (i <= @as(usize, @intCast(divisor.degree))) : (i += 1) {
            value.c[shift + i] = normalize(value.c[shift + i] - factor * divisor.c[i]);
        }
        trim(&value);
    }
    trim(&quotient);
    return quotient;
}

fn splitWithAffine(polynomial: Polynomial, slope: i64, offset: i64,
                   first: *Polynomial, second: *Polynomial) bool {
    var affine = Polynomial{};
    affine.c[0] = offset;
    affine.c[1] = slope;
    affine.degree = 1;
    affine = polyMod(affine, &polynomial);
    var powered = polynomialPowerMod(affine, @divTrunc(MODULUS - 1, 2), &polynomial);
    if (powered.degree < 0) {
        powered.c[0] = MODULUS - 1;
        powered.degree = 0;
    } else powered.c[0] = normalize(powered.c[0] - 1);
    trim(&powered);
    const part = polynomialGcd(polynomial, powered);
    if (part.degree <= 0 or part.degree >= polynomial.degree) return false;
    first.* = part;
    second.* = divideExact(polynomial, &part);
    return true;
}

fn collectRoots(polynomial: Polynomial, roots: *[MAX_N]i64, root_count: *usize, state_input: i64) void {
    if (polynomial.degree == 1) {
        roots[root_count.*] = normalize(-polynomial.c[0] * powerMod(polynomial.c[1], MODULUS - 2));
        root_count.* += 1;
        return;
    }
    var state = state_input;
    var first: Polynomial = undefined;
    var second: Polynomial = undefined;
    var attempt: usize = 0;
    while (attempt < 32) : (attempt += 1) {
        state = @rem(state * 48_271, PRNG_MODULUS);
        var slope = @rem(state, MODULUS);
        if (slope == 0) slope = 1;
        state = @rem(state * 48_271, PRNG_MODULUS);
        const offset = @rem(state, MODULUS);
        if (splitWithAffine(polynomial, slope, offset, &first, &second)) {
            collectRoots(first, roots, root_count, state);
            collectRoots(second, roots, root_count, state + 1);
            return;
        }
    }
    var offset: i64 = 0;
    while (offset < MODULUS) : (offset += 1) {
        if (splitWithAffine(polynomial, 1, offset, &first, &second)) {
            collectRoots(first, roots, root_count, state);
            collectRoots(second, roots, root_count, state + offset + 1);
            return;
        }
    }
}

fn findRoots(polynomial: Polynomial, roots: *[MAX_N]i64) usize {
    if (polynomial.degree <= 0) return 0;
    var x = Polynomial{};
    x.c[1] = 1;
    x.degree = 1;
    const x_mod = polyMod(x, &polynomial);
    var x_to_p = polynomialPowerMod(x_mod, MODULUS, &polynomial);
    const largest = @max(x_to_p.degree, x_mod.degree);
    var i: usize = 0;
    if (largest >= 0) {
        while (i <= @as(usize, @intCast(largest))) : (i += 1) {
            const left = if (@as(i64, @intCast(i)) <= x_to_p.degree) x_to_p.c[i] else 0;
            const right = if (@as(i64, @intCast(i)) <= x_mod.degree) x_mod.c[i] else 0;
            x_to_p.c[i] = normalize(left - right);
        }
    }
    x_to_p.degree = largest;
    trim(&x_to_p);
    const linear_part = polynomialGcd(polynomial, x_to_p);
    if (linear_part.degree <= 0) return 0;
    var seed: i64 = 1;
    i = 0;
    while (i <= @as(usize, @intCast(polynomial.degree))) : (i += 1) {
        seed = @rem(seed * 31 + polynomial.c[i], PRNG_MODULUS - 1) + 1;
    }
    var count: usize = 0;
    collectRoots(linear_part, roots, &count, seed);
    i = 0;
    while (i < count) : (i += 1) {
        var j = i + 1;
        while (j < count) : (j += 1) {
            if (roots[j] < roots[i]) {
                const temporary = roots[i];
                roots[i] = roots[j];
                roots[j] = temporary;
            }
        }
    }
    return count;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn polynomial_root_finding(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 8 or length != @as(usize, @intCast(input[0])) + 2) return -1;
    var polynomial = Polynomial{};
    polynomial.degree = input[0];
    var i: usize = 0;
    while (i <= @as(usize, @intCast(polynomial.degree))) : (i += 1) {
        const coefficient = input[i + 1];
        if (coefficient < 0 or coefficient >= MODULUS) return -1;
        polynomial.c[i] = coefficient;
    }
    if (polynomial.c[@intCast(polynomial.degree)] == 0) return -1;
    var roots = [_]i64{0} ** MAX_N;
    const root_count = findRoots(polynomial, &roots);
    const bytes = 8 * (root_count + 1);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    storeLe(output, 0, @intCast(root_count));
    for (0..root_count) |root_index| storeLe(output, 8 * (root_index + 1), roots[root_index]);
    return @intCast(bytes);
}

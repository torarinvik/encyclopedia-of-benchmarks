const MAX_N: usize = 8;
const MAX_POLY: usize = MAX_N + 1;
const MAX_FACTORS: usize = MAX_N;
const MAX_INPUT: usize = 12;
const MAX_OUTPUT_BYTES: usize = 216;
const Poly = [MAX_POLY]i64;

const Factor = struct {
    polynomial: Poly,
    degree: usize,
    multiplicity: i64,
};

fn powerSmall(base: usize, exponent: usize) usize {
    var value: usize = 1;
    for (0..exponent) |_| value *= base;
    return value;
}

fn monicFromCode(degree: usize, code_input: usize, prime: usize) Poly {
    var polynomial: Poly = @splat(0);
    var code = code_input;
    for (0..degree) |i| {
        polynomial[i] = @intCast(code % prime);
        code /= prime;
    }
    polynomial[degree] = 1;
    return polynomial;
}

fn exactQuotient(polynomial: *const Poly, degree: usize, divisor: *const Poly,
    divisor_degree: usize, prime: usize) ?Poly {
    if (degree < divisor_degree) return null;
    var remainder = polynomial.*;
    var quotient: Poly = @splat(0);
    const quotient_degree = degree - divisor_degree;
    for (0..quotient_degree + 1) |index| {
        const shift = quotient_degree - index;
        const factor = remainder[shift + divisor_degree];
        quotient[shift] = factor;
        for (0..divisor_degree + 1) |j| {
            var value = @rem(remainder[shift + j] - factor * divisor[j], @as(i64, @intCast(prime)));
            if (value < 0) value += @intCast(prime);
            remainder[shift + j] = value;
        }
    }
    for (0..divisor_degree) |i| if (remainder[i] != 0) return null;
    return quotient;
}

fn irreducible(candidate: *const Poly, degree: usize, prime: usize) bool {
    var divisor_degree: usize = 1;
    while (divisor_degree <= degree / 2) : (divisor_degree += 1) {
        for (0..powerSmall(prime, divisor_degree)) |code| {
            const divisor = monicFromCode(divisor_degree, code, prime);
            if (exactQuotient(candidate, degree, &divisor, divisor_degree, prime) != null) return false;
        }
    }
    return true;
}

fn after(left: Factor, right: Factor) bool {
    if (left.degree != right.degree) return left.degree > right.degree;
    for (0..left.degree + 1) |i| {
        if (left.polynomial[i] != right.polynomial[i]) return left.polynomial[i] > right.polynomial[i];
    }
    return false;
}

fn factorize(coefficients: *const Poly, input_degree: usize, prime: usize) struct {
    factors: [MAX_FACTORS]Factor,
    count: usize,
} {
    var factors: [MAX_FACTORS]Factor = undefined;
    var work = coefficients.*;
    var work_degree = input_degree;
    var factor_count: usize = 0;
    var degree: usize = 1;
    while (degree <= input_degree / 2) : (degree += 1) {
        for (0..powerSmall(prime, degree)) |code| {
            const candidate = monicFromCode(degree, code, prime);
            if (!irreducible(&candidate, degree, prime)) continue;
            var multiplicity: i64 = 0;
            while (work_degree >= degree) {
                const quotient = exactQuotient(&work, work_degree, &candidate, degree, prime) orelse break;
                work = quotient;
                work_degree -= degree;
                multiplicity += 1;
            }
            if (multiplicity != 0) {
                factors[factor_count] = .{ .polynomial = candidate, .degree = degree, .multiplicity = multiplicity };
                factor_count += 1;
            }
        }
    }
    if (work_degree > 0) {
        factors[factor_count] = .{ .polynomial = work, .degree = work_degree, .multiplicity = 1 };
        factor_count += 1;
    }
    for (0..factor_count) |i| {
        for (i + 1..factor_count) |j| {
            if (after(factors[i], factors[j])) {
                const temporary = factors[i];
                factors[i] = factors[j];
                factors[j] = temporary;
            }
        }
    }
    return .{ .factors = factors, .count = factor_count };
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn factorization_of_polynomials(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_N)) or
        (input[1] != 2 and input[1] != 3 and input[1] != 5)) return -1;
    const degree: usize = @intCast(input[0]);
    const prime: usize = @intCast(input[1]);
    if (length != degree + 3 or input[degree + 2] != 1) return -1;
    var coefficients: Poly = @splat(0);
    for (0..degree + 1) |i| {
        const coefficient = input[i + 2];
        if (coefficient < 0 or coefficient >= input[1]) return -1;
        coefficients[i] = coefficient;
    }

    const result = factorize(&coefficients, degree, prime);
    var words: usize = 1;
    for (0..result.count) |i| words += result.factors[i].degree + 3;
    const bytes = 8 * words;
    if (bytes > MAX_OUTPUT_BYTES) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var word: usize = 0;
    storeLe(output, 8 * word, @intCast(result.count));
    word += 1;
    for (0..result.count) |i| {
        const factor = result.factors[i];
        storeLe(output, 8 * word, factor.multiplicity);
        word += 1;
        storeLe(output, 8 * word, @intCast(factor.degree));
        word += 1;
        for (0..factor.degree + 1) |j| {
            storeLe(output, 8 * word, factor.polynomial[j]);
            word += 1;
        }
    }
    return @intCast(bytes);
}

const max_degree: i64 = 4;
const max_prime: i64 = 43;
const max_exponent: i64 = 6;
const max_modulus: i64 = 100_000;
const max_length: usize = 10;

fn normalizedMod(value: i64, modulus: i64) i64 {
    var result = @rem(value, modulus);
    if (result < 0) result += modulus;
    return result;
}

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn evaluate(coefficients: []const i64, x: i64, modulus: i64) i64 {
    var result: i64 = 0;
    var index: usize = coefficients.len;
    while (index > 0) {
        index -= 1;
        result = normalizedMod(result * x + coefficients[index], modulus);
    }
    return result;
}

fn derivative(coefficients: []const i64, x: i64, prime: i64) i64 {
    var result: i64 = 0;
    var index: usize = coefficients.len - 1;
    while (index > 0) {
        result = normalizedMod(result * x + @as(i64, @intCast(index)) * coefficients[index], prime);
        index -= 1;
    }
    return result;
}

export fn hensel_lifting_polynomial_root(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 6 or length > max_length) return -1;
    const words = input.?;
    const degree_value = words[0];
    const prime = words[1];
    const exponent = words[2];
    const seed = words[3];
    if (degree_value < 1 or degree_value > max_degree or prime < 2 or prime > max_prime) return -1;
    if (exponent < 1 or exponent > max_exponent or seed < 0 or seed >= prime) return -1;
    const degree: usize = @intCast(degree_value);
    if (length != degree + 5 or !isPrime(prime)) return -1;
    const coefficients = words[4 .. 5 + degree];
    for (coefficients) |coefficient| {
        if (coefficient < -1000 or coefficient > 1000) return -1;
    }

    var modulus: i64 = 1;
    var stage: i64 = 0;
    while (stage < exponent) : (stage += 1) {
        if (modulus > @divTrunc(max_modulus, prime)) return -1;
        modulus *= prime;
    }
    if (evaluate(coefficients, seed, prime) != 0) return -1;
    const derivative_value = derivative(coefficients, seed, prime);
    if (derivative_value == 0) return -1;
    var inverse: i64 = 0;
    var candidate: i64 = 1;
    while (candidate < prime) : (candidate += 1) {
        if (@rem(derivative_value * candidate, prime) == 1) {
            inverse = candidate;
            break;
        }
    }
    if (inverse == 0) return -1;

    var root = seed;
    var power = prime;
    stage = 1;
    while (stage < exponent) : (stage += 1) {
        const next_power = power * prime;
        const residue = evaluate(coefficients, root, next_power);
        const quotient_digit = @divTrunc(residue, power);
        const correction = normalizedMod(-quotient_digit * inverse, prime);
        root += correction * power;
        power = next_power;
    }
    return root;
}

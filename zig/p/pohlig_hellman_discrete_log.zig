/// Pohlig–Hellman discrete logarithm with prime-order BSGS digit searches.
const MIN_P: i64 = 3;
const MAX_P: i64 = 1_009;
const MAX_FACTORS: usize = 16;
const MAX_PARSEABLE_LENGTH: usize = 4;

const Factors = struct {
    primes: [MAX_FACTORS]i64 = [_]i64{0} ** MAX_FACTORS,
    exponents: [MAX_FACTORS]i64 = [_]i64{0} ** MAX_FACTORS,
    count: usize = 0,
};

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) {
        if (@rem(value, divisor) == 0) return false;
        if (divisor == 2) divisor = 3 else divisor += 2;
    }
    return true;
}

fn powMod(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var result: i64 = 1;
    var factor = @rem(base_value, modulus);
    var exponent = exponent_value;
    while (exponent > 0) {
        if (@rem(exponent, 2) == 1) result = @rem(result * factor, modulus);
        factor = @rem(factor * factor, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn factorize(input_value: i64) Factors {
    var factors = Factors{};
    var value = input_value;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) {
        if (@rem(value, divisor) != 0) {
            if (divisor == 2) divisor = 3 else divisor += 2;
            continue;
        }
        var exponent: i64 = 0;
        while (@rem(value, divisor) == 0) {
            value = @divTrunc(value, divisor);
            exponent += 1;
        }
        factors.primes[factors.count] = divisor;
        factors.exponents[factors.count] = exponent;
        factors.count += 1;
        if (divisor == 2) divisor = 3 else divisor += 2;
    }
    if (value > 1) {
        factors.primes[factors.count] = value;
        factors.exponents[factors.count] = 1;
        factors.count += 1;
    }
    return factors;
}

fn primeOrderLog(generator: i64, target: i64, order: i64, modulus: i64) i64 {
    var step: i64 = 1;
    while (step * step < order) step += 1;
    var baby: [64]i64 = [_]i64{0} ** 64;
    var value: i64 = 1;
    var j: i64 = 0;
    while (j < step) : (j += 1) {
        baby[@intCast(j)] = value;
        value = @rem(value * generator, modulus);
    }
    const giant_factor = powMod(powMod(generator, step, modulus), modulus - 2, modulus);
    var probe = target;
    var i: i64 = 0;
    while (i <= step) : (i += 1) {
        j = 0;
        while (j < step) : (j += 1) {
            if (baby[@intCast(j)] == probe) {
                const candidate = i * step + j;
                if (candidate < order) return candidate;
            }
        }
        probe = @rem(probe * giant_factor, modulus);
    }
    return -1;
}

fn inverseMod(value: i64, modulus: i64) i64 {
    var old_r = value;
    var r = modulus;
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
    if (old_r != 1) return -1;
    return @mod(old_s, modulus);
}

fn pohligHellman(p: i64, base: i64, target: i64) i64 {
    if (target == 0) return -2;
    const p_factors = factorize(p - 1);
    var order = p - 1;
    for (0..p_factors.count) |index| {
        const prime = p_factors.primes[index];
        while (@rem(order, prime) == 0 and powMod(base, @divTrunc(order, prime), p) == 1) {
            order = @divTrunc(order, prime);
        }
    }
    if (order == 1) return if (target == 1) 0 else -2;

    const order_factors = factorize(order);
    var solution: i64 = 0;
    var combined_modulus: i64 = 1;
    for (0..order_factors.count) |index| {
        const prime = order_factors.primes[index];
        const exponent = order_factors.exponents[index];
        var component_modulus: i64 = 1;
        var j: i64 = 0;
        while (j < exponent) : (j += 1) component_modulus *= prime;
        var partial_log: i64 = 0;
        var place: i64 = 1;
        const prime_generator = powMod(base, @divTrunc(order, prime), p);
        var digit_index: i64 = 0;
        while (digit_index < exponent) : (digit_index += 1) {
            const current_power = powMod(base, partial_log, p);
            const inverse_current = powMod(current_power, p - 2, p);
            const residual = @rem(target * inverse_current, p);
            const digit_target = powMod(residual, @divTrunc(order, place * prime), p);
            const digit = primeOrderLog(prime_generator, digit_target, prime, p);
            if (digit < 0) return -2;
            partial_log += digit * place;
            place *= prime;
        }
        if (combined_modulus == 1) {
            solution = partial_log;
            combined_modulus = component_modulus;
        } else {
            const inverse = inverseMod(@rem(combined_modulus, component_modulus), component_modulus);
            if (inverse < 0) return -2;
            const difference = @mod(partial_log - solution, component_modulus);
            const adjustment = @rem(difference * inverse, component_modulus);
            solution += combined_modulus * adjustment;
            combined_modulus *= component_modulus;
        }
    }
    solution = @rem(solution, order);
    return if (powMod(base, solution, p) == target) solution else -2;
}

fn verify(values: []const i64) i64 {
    if (values.len != 3) return -1;
    const p = values[0];
    const base = values[1];
    const target = values[2];
    if (p < MIN_P or p > MAX_P or !isPrime(p) or base < 1 or base >= p or target < 0 or target >= p) return -1;
    return pohligHellman(p, base, target);
}

export fn pohlig_hellman_discrete_log(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH or length != 3) return -1;
    return verify(input.?[0..length]);
}

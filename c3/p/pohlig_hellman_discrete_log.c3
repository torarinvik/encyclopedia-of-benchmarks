module pohlig_hellman_discrete_log;

const long MIN_P = 3;
const long MAX_P = 1009;
const int MAX_FACTORS = 16;
const usz MAX_PARSEABLE_LENGTH = 4;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long pow_mod(long base, long exponent, long modulus) {
    long result = 1;
    long factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * factor % modulus;
        factor = factor * factor % modulus;
        exponent >>= 1;
    }
    return result;
}

fn int factorize(long value, long[MAX_FACTORS]* primes, long[MAX_FACTORS]* exponents) {
    int count = 0;
    for (long divisor = 2; divisor * divisor <= value; divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor != 0) continue;
        long exponent = 0;
        do {
            value /= divisor;
            exponent++;
        } while (value % divisor == 0);
        (*primes)[count] = divisor;
        (*exponents)[count] = exponent;
        count++;
    }
    if (value > 1) {
        (*primes)[count] = value;
        (*exponents)[count] = 1;
        count++;
    }
    return count;
}

fn long prime_order_log(long generator, long target, long order, long modulus) {
    long step = 1;
    while (step * step < order) step++;
    long[64] baby;
    long value = 1;
    for (long j = 0; j < step; j++) {
        baby[j] = value;
        value = value * generator % modulus;
    }
    long giant_factor = pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus);
    long probe = target;
    for (long i = 0; i <= step; i++) {
        for (long j = 0; j < step; j++) {
            if (baby[j] == probe) {
                long candidate = i * step + j;
                if (candidate < order) return candidate;
            }
        }
        probe = probe * giant_factor % modulus;
    }
    return -1;
}

fn long inverse_mod(long value, long modulus) {
    long old_r = value; long r = modulus;
    long old_s = 1; long s = 0;
    while (r != 0) {
        long quotient = old_r / r;
        long next_r = old_r - quotient * r;
        long next_s = old_s - quotient * s;
        old_r = r; r = next_r;
        old_s = s; s = next_s;
    }
    if (old_r != 1) return -1;
    return (old_s % modulus + modulus) % modulus;
}

fn long pohlig_hellman(long p, long base, long target) {
    if (target == 0) return -2;
    long[MAX_FACTORS] primes = zeroed;
    long[MAX_FACTORS] exponents = zeroed;
    int factor_count = factorize(p - 1, &primes, &exponents);
    long order = p - 1;
    for (int i = 0; i < factor_count; i++) {
        while (order % primes[i] == 0 && pow_mod(base, order / primes[i], p) == 1) {
            order /= primes[i];
        }
    }
    if (order == 1) return target == 1 ? 0 : -2;

    long[MAX_FACTORS] order_primes = zeroed;
    long[MAX_FACTORS] order_exponents = zeroed;
    int order_factor_count = factorize(order, &order_primes, &order_exponents);
    long solution = 0;
    long combined_modulus = 1;
    for (int i = 0; i < order_factor_count; i++) {
        long prime = order_primes[i];
        long exponent = order_exponents[i];
        long component_modulus = 1;
        for (long j = 0; j < exponent; j++) component_modulus *= prime;
        long partial_log = 0;
        long place = 1;
        long prime_generator = pow_mod(base, order / prime, p);
        for (long digit_index = 0; digit_index < exponent; digit_index++) {
            long current_power = pow_mod(base, partial_log, p);
            long inverse_current = pow_mod(current_power, p - 2, p);
            long residual = target * inverse_current % p;
            long digit_target = pow_mod(residual, order / (place * prime), p);
            long digit = prime_order_log(prime_generator, digit_target, prime, p);
            if (digit < 0) return -2;
            partial_log += digit * place;
            place *= prime;
        }
        if (combined_modulus == 1) {
            solution = partial_log;
            combined_modulus = component_modulus;
        } else {
            long inverse = inverse_mod(combined_modulus % component_modulus, component_modulus);
            if (inverse < 0) return -2;
            long difference = (partial_log - solution) % component_modulus;
            long adjustment = ((difference + component_modulus) % component_modulus) * inverse % component_modulus;
            solution += combined_modulus * adjustment;
            combined_modulus *= component_modulus;
        }
    }
    solution %= order;
    return pow_mod(base, solution, p) == target ? solution : -2;
}

fn long pohlig_hellman_discrete_log(long* input, usz length)
        @export("pohlig_hellman_discrete_log") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 3) return -1;
    long p = input[0]; long base = input[1]; long target = input[2];
    if (p < MIN_P || p > MAX_P || !is_prime(p) || base < 1 || base >= p || target < 0 || target >= p) return -1;
    return pohlig_hellman(p, base, target);
}

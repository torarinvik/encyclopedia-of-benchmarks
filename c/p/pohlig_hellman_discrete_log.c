#include <stddef.h>
#include <stdint.h>

enum { MIN_P = 3, MAX_P = 1009, MAX_FACTORS = 16, MAX_PARSEABLE_LENGTH = 4 };

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t pow_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    int64_t factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * factor % modulus;
        factor = factor * factor % modulus;
        exponent >>= 1;
    }
    return result;
}

static int factorize(int64_t value, int64_t *primes, int64_t *exponents) {
    int count = 0;
    for (int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor != 0) continue;
        int64_t exponent = 0;
        do {
            value /= divisor;
            ++exponent;
        } while (value % divisor == 0);
        primes[count] = divisor;
        exponents[count] = exponent;
        ++count;
    }
    if (value > 1) {
        primes[count] = value;
        exponents[count] = 1;
        ++count;
    }
    return count;
}

static int64_t prime_order_log(int64_t generator, int64_t target,
                               int64_t order, int64_t modulus) {
    int64_t step = 1;
    while (step * step < order) ++step;
    int64_t baby[64];
    int64_t value = 1;
    for (int64_t j = 0; j < step; ++j) {
        baby[j] = value;
        value = value * generator % modulus;
    }
    int64_t giant_factor = pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus);
    int64_t probe = target;
    for (int64_t i = 0; i <= step; ++i) {
        for (int64_t j = 0; j < step; ++j) {
            if (baby[j] == probe) {
                const int64_t candidate = i * step + j;
                if (candidate < order) return candidate;
            }
        }
        probe = probe * giant_factor % modulus;
    }
    return -1;
}

static int64_t inverse_mod(int64_t value, int64_t modulus) {
    int64_t old_r = value, r = modulus;
    int64_t old_s = 1, s = 0;
    while (r != 0) {
        const int64_t quotient = old_r / r;
        const int64_t next_r = old_r - quotient * r;
        const int64_t next_s = old_s - quotient * s;
        old_r = r; r = next_r;
        old_s = s; s = next_s;
    }
    if (old_r != 1) return -1;
    return (old_s % modulus + modulus) % modulus;
}

static int64_t pohlig_hellman(int64_t p, int64_t base, int64_t target) {
    if (target == 0) return -2;
    int64_t primes[MAX_FACTORS] = {0}, exponents[MAX_FACTORS] = {0};
    const int factor_count = factorize(p - 1, primes, exponents);
    int64_t order = p - 1;
    for (int i = 0; i < factor_count; ++i) {
        while (order % primes[i] == 0
               && pow_mod(base, order / primes[i], p) == 1) {
            order /= primes[i];
        }
    }
    if (order == 1) return target == 1 ? 0 : -2;

    int64_t order_primes[MAX_FACTORS] = {0}, order_exponents[MAX_FACTORS] = {0};
    const int order_factor_count = factorize(order, order_primes, order_exponents);
    int64_t solution = 0;
    int64_t combined_modulus = 1;
    for (int i = 0; i < order_factor_count; ++i) {
        const int64_t prime = order_primes[i];
        const int64_t exponent = order_exponents[i];

        int64_t component_modulus = 1;
        for (int64_t j = 0; j < exponent; ++j) component_modulus *= prime;
        int64_t partial_log = 0;
        int64_t place = 1;
        const int64_t prime_generator = pow_mod(base, order / prime, p);
        for (int64_t digit_index = 0; digit_index < exponent; ++digit_index) {
            const int64_t current_power = pow_mod(base, partial_log, p);
            const int64_t inverse_current = pow_mod(current_power, p - 2, p);
            const int64_t residual = target * inverse_current % p;
            const int64_t digit_target = pow_mod(residual, order / (place * prime), p);
            const int64_t digit = prime_order_log(prime_generator, digit_target, prime, p);
            if (digit < 0) return -2;
            partial_log += digit * place;
            place *= prime;
        }

        if (combined_modulus == 1) {
            solution = partial_log;
            combined_modulus = component_modulus;
        } else {
            const int64_t inverse = inverse_mod(combined_modulus % component_modulus,
                                                component_modulus);
            if (inverse < 0) return -2;
            const int64_t difference = (partial_log - solution) % component_modulus;
            const int64_t adjustment = ((difference + component_modulus) % component_modulus)
                                       * inverse % component_modulus;
            solution += combined_modulus * adjustment;
            combined_modulus *= component_modulus;
        }
    }
    solution %= order;
    return pow_mod(base, solution, p) == target ? solution : -2;
}

int64_t pohlig_hellman_discrete_log(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 3) return -1;
    const int64_t p = input[0], base = input[1], target = input[2];
    if (p < MIN_P || p > MAX_P || !is_prime(p) || base < 1 || base >= p
        || target < 0 || target >= p) return -1;
    return pohlig_hellman(p, base, target);
}

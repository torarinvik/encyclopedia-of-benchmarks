#include <stddef.h>
#include <stdint.h>

#define MAX_NUM INT64_C(1000000000)
#define U32_MOD INT64_C(4294967296)
#define ITERATIONS_BEFORE_CHECK INT64_C(32)
#define ITERATIONS_CUTOFF INT64_C(262144)

static int64_t gcd_nonnegative(int64_t left, int64_t right) {
    while (left != 0) {
        const int64_t remainder = right % left;
        right = left;
        left = remainder;
    }
    return right;
}

static int64_t mod_power(int64_t base, int64_t power, int64_t modulus) {
    base %= modulus;
    if (base == 0) return 0;
    int64_t result = 1;
    while (power > 0) {
        if (power % 2 != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        power /= 2;
    }
    return result;
}

static int probable_prime(int64_t number) {
    if (number <= 4) return number == 2 || number == 3;
    const int64_t bases[] = {2, 3, 5, 7};
    for (size_t i = 0; i < sizeof(bases) / sizeof(bases[0]); ++i)
        if (number == bases[i]) return 1;
    int64_t odd_power = number - 1;
    int64_t two_power = 0;
    while (odd_power % 2 == 0) { odd_power /= 2; ++two_power; }
    for (size_t i = 0; i < sizeof(bases) / sizeof(bases[0]); ++i) {
        int64_t value = mod_power(bases[i], odd_power, number);
        if (value == 1 || value == number - 1) continue;
        int passed = 0;
        for (int64_t r = 1; r < two_power; ++r) {
            value = (value * value) % number;
            if (value == number - 1) { passed = 1; break; }
        }
        if (!passed) return 0;
    }
    return 1;
}

static int64_t lcg_next(int64_t *state) {
    *state = (INT64_C(1103515245) * *state + INT64_C(12345)) % U32_MOD;
    return *state;
}

static int64_t draw_mod(int64_t *state, int64_t modulus) {
    const int64_t high = lcg_next(state);
    const int64_t low = lcg_next(state);
    return ((high % modulus) * (U32_MOD % modulus) + low % modulus) % modulus;
}

static int64_t advance(int64_t x, int64_t c, int64_t number) {
    return (x * x + c) % number;
}

static int64_t brent_factor(int64_t number, int64_t x0, int64_t c) {
    int64_t x = x0, x_start = 0, y = 0, remainder = 1, current_gcd = 1;
    int64_t max_iterations = 1;
    while (current_gcd == 1) {
        y = x;
        for (int64_t i = 1; i < max_iterations; ++i) x = advance(x, c, number);
        int64_t big_iteration = 0;
        while (big_iteration < max_iterations && current_gcd == 1) {
            x_start = x;
            int64_t small_iteration = 0;
            while (small_iteration < ITERATIONS_BEFORE_CHECK &&
                   small_iteration < max_iterations - big_iteration) {
                ++small_iteration;
                x = advance(x, c, number);
                const int64_t difference = x >= y ? x - y : y - x;
                remainder = (remainder * difference) % number;
            }
            current_gcd = gcd_nonnegative(remainder, number);
            big_iteration += ITERATIONS_BEFORE_CHECK;
        }
        max_iterations *= 2;
        if (max_iterations > ITERATIONS_CUTOFF) break;
    }
    if (current_gcd == number) {
        while (current_gcd == 1) {
            x_start = advance(x_start, c, number);
            const int64_t difference = x_start >= y ? x_start - y : y - x_start;
            current_gcd = gcd_nonnegative(difference, number);
        }
    }
    return current_gcd;
}

int64_t pollard_rho_rust(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t number = input[0];
    int64_t state = input[1];
    const int64_t restart_limit = input[2];
    if (number < 2 || number > MAX_NUM || state < 0 || state >= U32_MOD ||
        restart_limit < 1 || restart_limit > 16) return -1;
    if (probable_prime(number)) return number;

    for (int64_t restart = 0; restart < restart_limit; ++restart) {
        const int64_t x0 = draw_mod(&state, number - 3) + 2;
        const int64_t c = draw_mod(&state, number - 2) + 1;
        const int64_t factor = brent_factor(number, x0, c);
        if (factor != 1 && factor != number) return factor;
    }
    return 0;
}

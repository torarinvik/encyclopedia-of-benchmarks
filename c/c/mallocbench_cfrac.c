/*
 * Clean-room bounded CFRAC profile based on the published
 * Morrison-Brillhart continued-fraction factorization method.
 * No code from the restricted arbitrary-precision package is included.
 */
#include <stddef.h>
#include <stdint.h>

#define CFRAC_MAX_BASE 10
#define CFRAC_MAX_ITERATIONS 48
#define CFRAC_MAX_PRIME 10000

static uint64_t cfrac_gcd(uint64_t a, uint64_t b)
{
    while (b != 0) {
        const uint64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static uint64_t cfrac_modpow(uint64_t base, uint64_t exponent, uint64_t modulus)
{
    uint64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if (exponent & 1u) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int cfrac_is_prime(unsigned value)
{
    if (value < 2) return 0;
    for (unsigned divisor = 2; (uint64_t)divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static int cfrac_base(uint64_t n, unsigned requested, uint32_t *base)
{
    unsigned count = 1;
    base[0] = 2;
    for (unsigned p = 3; p <= CFRAC_MAX_PRIME && count < requested; p += 2) {
        if (!cfrac_is_prime(p)) continue;
        const uint64_t residue = cfrac_modpow(n % p, (p - 1) / 2, p);
        if (residue == 0) return 0; /* Source selects residue 0; this profile rejects that domain. */
        if (residue == 1) base[count++] = p;
    }
    return count == requested;
}

static int cfrac_factor_from_dependency(uint64_t n, uint64_t selected,
    unsigned relation_count, const uint64_t relation_a[CFRAC_MAX_ITERATIONS],
    const uint8_t relation_exp[CFRAC_MAX_ITERATIONS][CFRAC_MAX_BASE],
    const uint32_t *base, unsigned base_count)
{
    uint64_t x = 1;
    uint64_t exponent_sum[CFRAC_MAX_BASE] = {0};
    for (unsigned i = 0; i < relation_count; ++i) {
        if ((selected & (UINT64_C(1) << i)) == 0) continue;
        x = (x * relation_a[i]) % n;
        for (unsigned j = 0; j < base_count; ++j) exponent_sum[j] += relation_exp[i][j];
    }
    uint64_t y = 1;
    for (unsigned j = 0; j < base_count; ++j)
        y = (y * cfrac_modpow(base[j], exponent_sum[j] / 2, n)) % n;
    const uint64_t minus = cfrac_gcd(x >= y ? x - y : y - x, n);
    if (minus > 1 && minus < n) return (int)minus;
    const uint64_t plus = cfrac_gcd(x + y, n);
    if (plus > 1 && plus < n) return (int)plus;
    return 0;
}

int64_t mallocbench_cfrac(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    const int64_t n_value = input[0], base_value = input[1], iteration_value = input[2];
    if (n_value < 15 || n_value > 1000000 || (n_value & 1) == 0 ||
        base_value < 2 || base_value > CFRAC_MAX_BASE ||
        iteration_value < 1 || iteration_value > CFRAC_MAX_ITERATIONS) return -1;
    const uint64_t n = (uint64_t)n_value;
    uint64_t root = 0;
    while ((root + 1) <= n / (root + 1)) ++root;
    if (root * root == n) return -1;

    const unsigned base_count = (unsigned)base_value;
    const unsigned iteration_limit = (unsigned)iteration_value;
    uint32_t base[CFRAC_MAX_BASE] = {0};
    if (!cfrac_base(n, base_count, base)) return -1;

    uint64_t basis_vector[CFRAC_MAX_BASE + 1] = {0};
    uint64_t basis_combo[CFRAC_MAX_BASE + 1] = {0};
    uint8_t basis_used[CFRAC_MAX_BASE + 1] = {0};
    uint64_t relation_a[CFRAC_MAX_ITERATIONS] = {0};
    uint8_t relation_exp[CFRAC_MAX_ITERATIONS][CFRAC_MAX_BASE] = {{0}};
    unsigned relation_count = 0;

    int64_t u = (int64_t)(2 * root), previous_u = (int64_t)(2 * root);
    int64_t q_value = 0, q_denominator = 1;
    int64_t previous_denominator = (int64_t)(n - root * root);
    int64_t a_value = 1, previous_a = (int64_t)root;
    unsigned sign = 0;

    for (unsigned iteration = 0; iteration < iteration_limit; ++iteration) {
        const int64_t old_a = a_value;
        a_value = (q_value * a_value + previous_a) % (int64_t)n;
        previous_a = old_a;

        const int64_t old_denominator = q_denominator;
        q_denominator = q_value * (previous_u - u) + previous_denominator;
        previous_denominator = old_denominator;
        previous_u = u;

        if (q_denominator <= 0) return (int64_t)n;
        q_value = 1;
        int64_t remainder = u - q_denominator;
        if (remainder >= q_denominator) {
            q_value = u / q_denominator;
            remainder = u % q_denominator;
        }
        u = (int64_t)(2 * root) - remainder;
        sign ^= 1u;

        /* The source treats Q=1 as a repeated-cycle termination. */
        if (q_denominator == 1) return (int64_t)n;

        uint64_t residual = (uint64_t)q_denominator;
        uint8_t exponents[CFRAC_MAX_BASE] = {0};
        for (unsigned j = 0; j < base_count; ++j) {
            while (residual % base[j] == 0) {
                residual /= base[j];
                ++exponents[j];
            }
        }
        if (residual != 1) continue;

        relation_a[relation_count] = (uint64_t)a_value;
        for (unsigned j = 0; j < base_count; ++j) relation_exp[relation_count][j] = exponents[j];
        uint64_t vector = (uint64_t)sign;
        for (unsigned j = 0; j < base_count; ++j)
            if (exponents[j] & 1u) vector |= UINT64_C(1) << (j + 1);
        uint64_t combination = UINT64_C(1) << relation_count;
        ++relation_count;

        int inserted = 0;
        for (unsigned bit = 0; bit <= base_count; ++bit) {
            if ((vector & (UINT64_C(1) << bit)) == 0) continue;
            if (basis_used[bit]) {
                vector ^= basis_vector[bit];
                combination ^= basis_combo[bit];
            } else {
                basis_used[bit] = 1;
                basis_vector[bit] = vector;
                basis_combo[bit] = combination;
                inserted = 1;
                break;
            }
        }
        if (!inserted) {
            const int factor = cfrac_factor_from_dependency(n, combination, relation_count,
                relation_a, relation_exp, base, base_count);
            if (factor > 1) return factor;
        }
    }
    return (int64_t)n;
}

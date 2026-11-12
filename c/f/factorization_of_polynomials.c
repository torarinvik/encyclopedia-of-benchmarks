#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_POLY = 9, MAX_FACTORS = 8, MAX_INPUT = 12 };

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int supported_prime(int64_t p)
{
    return p == 2 || p == 3 || p == 5;
}

static int power_small(int base, int exponent)
{
    int value = 1;
    for (int i = 0; i < exponent; ++i) value *= base;
    return value;
}

static void monic_from_code(int64_t *polynomial, int degree, int code, int prime)
{
    for (int i = 0; i < degree; ++i) {
        polynomial[i] = code % prime;
        code /= prime;
    }
    polynomial[degree] = 1;
}

static int exact_quotient(const int64_t *polynomial, int degree,
                          const int64_t *divisor, int divisor_degree,
                          int prime, int64_t *quotient)
{
    if (degree < divisor_degree) return 0;
    int64_t remainder[MAX_POLY] = {0};
    for (int i = 0; i <= degree; ++i) remainder[i] = polynomial[i];
    int quotient_degree = degree - divisor_degree;
    for (int i = 0; i <= quotient_degree; ++i) quotient[i] = 0;
    for (int shift = quotient_degree; shift >= 0; --shift) {
        int64_t factor = remainder[shift + divisor_degree];
        quotient[shift] = factor;
        for (int j = 0; j <= divisor_degree; ++j) {
            int64_t value = remainder[shift + j] - factor * divisor[j];
            value %= prime;
            if (value < 0) value += prime;
            remainder[shift + j] = value;
        }
    }
    for (int i = 0; i < divisor_degree; ++i)
        if (remainder[i] != 0) return 0;
    return 1;
}

static int irreducible(const int64_t *candidate, int degree, int prime)
{
    for (int divisor_degree = 1; divisor_degree <= degree / 2; ++divisor_degree) {
        int limit = power_small(prime, divisor_degree);
        for (int code = 0; code < limit; ++code) {
            int64_t divisor[MAX_POLY] = {0};
            int64_t quotient[MAX_POLY] = {0};
            monic_from_code(divisor, divisor_degree, code, prime);
            if (exact_quotient(candidate, degree, divisor, divisor_degree,
                               prime, quotient)) return 0;
        }
    }
    return 1;
}

static void swap_factors(int64_t factors[MAX_FACTORS][MAX_POLY],
                         int *degrees, int64_t *multiplicities, int left, int right)
{
    int64_t coefficient_row[MAX_POLY];
    for (int j = 0; j < MAX_POLY; ++j) {
        coefficient_row[j] = factors[left][j];
        factors[left][j] = factors[right][j];
        factors[right][j] = coefficient_row[j];
    }
    int degree = degrees[left];
    degrees[left] = degrees[right];
    degrees[right] = degree;
    int64_t multiplicity = multiplicities[left];
    multiplicities[left] = multiplicities[right];
    multiplicities[right] = multiplicity;
}

static int factor_polynomial(const int64_t *coefficients, int input_degree,
                             int prime, int64_t factors[MAX_FACTORS][MAX_POLY],
                             int *degrees, int64_t *multiplicities)
{
    int64_t work[MAX_POLY] = {0};
    for (int i = 0; i <= input_degree; ++i) work[i] = coefficients[i];
    int work_degree = input_degree;
    int factor_count = 0;

    for (int degree = 1; degree <= input_degree / 2; ++degree) {
        int limit = power_small(prime, degree);
        for (int code = 0; code < limit; ++code) {
            int64_t candidate[MAX_POLY] = {0};
            monic_from_code(candidate, degree, code, prime);
            if (!irreducible(candidate, degree, prime)) continue;
            int64_t quotient[MAX_POLY] = {0};
            int64_t multiplicity = 0;
            while (work_degree >= degree &&
                   exact_quotient(work, work_degree, candidate, degree, prime, quotient)) {
                ++multiplicity;
                work_degree -= degree;
                for (int i = 0; i <= work_degree; ++i) work[i] = quotient[i];
            }
            if (multiplicity != 0) {
                degrees[factor_count] = degree;
                multiplicities[factor_count] = multiplicity;
                for (int i = 0; i <= degree; ++i) factors[factor_count][i] = candidate[i];
                ++factor_count;
            }
        }
    }
    if (work_degree > 0) {
        degrees[factor_count] = work_degree;
        multiplicities[factor_count] = 1;
        for (int i = 0; i <= work_degree; ++i) factors[factor_count][i] = work[i];
        ++factor_count;
    }

    for (int i = 0; i < factor_count; ++i) {
        for (int j = i + 1; j < factor_count; ++j) {
            int after = degrees[i] > degrees[j];
            if (degrees[i] == degrees[j]) {
                for (int k = 0; k <= degrees[i]; ++k) {
                    if (factors[i][k] == factors[j][k]) continue;
                    after = factors[i][k] > factors[j][k];
                    break;
                }
            }
            if (after) swap_factors(factors, degrees, multiplicities, i, j);
        }
    }
    return factor_count;
}

int64_t factorization_of_polynomials(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t degree_value = input[0];
    int64_t prime_value = input[1];
    if (degree_value < 0 || degree_value > MAX_N || !supported_prime(prime_value) ||
        length != (size_t)degree_value + 3) return -1;
    int degree = (int)degree_value;
    int prime = (int)prime_value;
    if (input[degree + 2] != 1) return -1;
    for (int i = 0; i <= degree; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= prime) return -1;

    int64_t factors[MAX_FACTORS][MAX_POLY] = {{0}};
    int degrees[MAX_FACTORS] = {0};
    int64_t multiplicities[MAX_FACTORS] = {0};
    int factor_count = factor_polynomial(input + 2, degree, prime,
                                         factors, degrees, multiplicities);
    size_t words = 1;
    for (int i = 0; i < factor_count; ++i) words += (size_t)degrees[i] + 3;
    size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;

    size_t word = 0;
    store_le(output, 8 * word++, factor_count);
    for (int i = 0; i < factor_count; ++i) {
        store_le(output, 8 * word++, multiplicities[i]);
        store_le(output, 8 * word++, degrees[i]);
        for (int j = 0; j <= degrees[i]; ++j)
            store_le(output, 8 * word++, factors[i][j]);
    }
    return (int64_t)bytes;
}

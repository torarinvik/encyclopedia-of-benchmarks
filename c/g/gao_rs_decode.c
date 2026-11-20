#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { GAO_FIELD = 7, GAO_MAX_N = 7, GAO_MAX_K = 3, GAO_POLY = 8 };

static int gao_mod7(int value)
{
    value %= GAO_FIELD;
    return value < 0 ? value + GAO_FIELD : value;
}

static int gao_inverse7(int value)
{
    switch (value) {
        case 1: return 1;
        case 2: return 4;
        case 3: return 5;
        case 4: return 2;
        case 5: return 3;
        case 6: return 6;
        default: return 0;
    }
}

static bool gao_is_zero(const int polynomial[GAO_POLY])
{
    for (size_t degree = 0; degree < GAO_POLY; ++degree)
        if (polynomial[degree] != 0) return false;
    return true;
}

static size_t gao_degree(const int polynomial[GAO_POLY])
{
    for (size_t degree = GAO_POLY; degree > 0; --degree)
        if (polynomial[degree - 1] != 0) return degree - 1;
    return 0;
}

static void gao_copy(int destination[GAO_POLY], const int source[GAO_POLY])
{
    for (size_t degree = 0; degree < GAO_POLY; ++degree)
        destination[degree] = source[degree];
}

static void gao_multiply_linear(int polynomial[GAO_POLY], int constant)
{
    int product[GAO_POLY] = {0};
    for (size_t degree = 0; degree < GAO_POLY; ++degree) {
        product[degree] = gao_mod7(product[degree] - constant * polynomial[degree]);
        if (degree + 1 < GAO_POLY)
            product[degree + 1] = gao_mod7(product[degree + 1] + polynomial[degree]);
    }
    gao_copy(polynomial, product);
}

static void gao_interpolate(size_t n, const int64_t values[GAO_MAX_N],
                            int result[GAO_POLY])
{
    for (size_t i = 0; i < n; ++i) {
        int basis[GAO_POLY] = {1, 0, 0, 0, 0, 0, 0, 0};
        int denominator = 1;
        for (size_t j = 0; j < n; ++j) {
            if (j == i) continue;
            gao_multiply_linear(basis, (int)j);
            denominator = gao_mod7(denominator * ((int)i - (int)j));
        }
        const int scale = gao_mod7((int)values[i] * gao_inverse7(denominator));
        for (size_t degree = 0; degree < GAO_POLY; ++degree)
            result[degree] = gao_mod7(result[degree] + scale * basis[degree]);
    }
}

static void gao_build_vanishing(size_t n, int result[GAO_POLY])
{
    result[0] = 1;
    for (size_t point = 0; point < n; ++point)
        gao_multiply_linear(result, (int)point);
}

static bool gao_divide(const int numerator[GAO_POLY], const int denominator[GAO_POLY],
                       int quotient[GAO_POLY], int remainder[GAO_POLY])
{
    if (gao_is_zero(denominator)) return false;
    for (size_t degree = 0; degree < GAO_POLY; ++degree) {
        quotient[degree] = 0;
        remainder[degree] = numerator[degree];
    }
    const size_t denominator_degree = gao_degree(denominator);
    size_t remainder_degree = gao_degree(remainder);
    const int inverse_lead = gao_inverse7(denominator[denominator_degree]);
    while (!gao_is_zero(remainder) && remainder_degree >= denominator_degree) {
        const size_t shift = remainder_degree - denominator_degree;
        const int factor = gao_mod7(remainder[remainder_degree] * inverse_lead);
        quotient[shift] = gao_mod7(quotient[shift] + factor);
        for (size_t degree = 0; degree <= denominator_degree; ++degree)
            remainder[shift + degree] = gao_mod7(
                remainder[shift + degree] - factor * denominator[degree]);
        remainder_degree = gao_degree(remainder);
    }
    return true;
}

static void gao_multiply(const int left[GAO_POLY], const int right[GAO_POLY],
                         int product[GAO_POLY])
{
    for (size_t degree = 0; degree < GAO_POLY; ++degree) product[degree] = 0;
    for (size_t i = 0; i < GAO_POLY; ++i)
        for (size_t j = 0; j < GAO_POLY && i + j < GAO_POLY; ++j)
            product[i + j] = gao_mod7(product[i + j] + left[i] * right[j]);
}

static void gao_subtract(int result[GAO_POLY], const int left[GAO_POLY],
                         const int right[GAO_POLY])
{
    for (size_t degree = 0; degree < GAO_POLY; ++degree)
        result[degree] = gao_mod7(left[degree] - right[degree]);
}

static int64_t gao_decode(size_t n, size_t k, size_t errors,
                          const int64_t received[GAO_MAX_N])
{
    int interpolant[GAO_POLY] = {0};
    gao_interpolate(n, received, interpolant);
    if (gao_is_zero(interpolant)) return 1;

    int r0[GAO_POLY] = {0};
    int r1[GAO_POLY] = {0};
    gao_build_vanishing(n, r0);
    gao_copy(r1, interpolant);
    int v0[GAO_POLY] = {0};
    int v1[GAO_POLY] = {1, 0, 0, 0, 0, 0, 0, 0};
    int candidate_numerator[GAO_POLY] = {0};
    int candidate_denominator[GAO_POLY] = {0};
    bool found = false;

    while (!gao_is_zero(r1)) {
        if (2 * gao_degree(r1) < n + k) {
            gao_copy(candidate_numerator, r1);
            gao_copy(candidate_denominator, v1);
            found = true;
            break;
        }
        int quotient[GAO_POLY] = {0};
        int remainder[GAO_POLY] = {0};
        if (!gao_divide(r0, r1, quotient, remainder)) return 0;
        if (gao_is_zero(remainder)) break;
        int product[GAO_POLY] = {0};
        int v2[GAO_POLY] = {0};
        gao_multiply(quotient, v1, product);
        gao_subtract(v2, v0, product);
        gao_copy(r0, r1);
        gao_copy(r1, remainder);
        gao_copy(v0, v1);
        gao_copy(v1, v2);
    }
    if (!found || gao_is_zero(candidate_denominator)) return 0;

    int coefficients[GAO_POLY] = {0};
    int division_remainder[GAO_POLY] = {0};
    if (!gao_divide(candidate_numerator, candidate_denominator,
                    coefficients, division_remainder)
        || !gao_is_zero(division_remainder)
        || gao_degree(coefficients) >= k) return 0;

    size_t mismatches = 0;
    for (size_t x = 0; x < n; ++x) {
        int value = 0;
        for (size_t degree = k; degree > 0; --degree)
            value = (value * (int)x + coefficients[degree - 1]) % GAO_FIELD;
        if (value != received[x]) ++mismatches;
    }
    if (mismatches > errors) return 0;

    int64_t result = 1;
    int64_t place = 1;
    for (size_t degree = 0; degree < k; ++degree) {
        result += coefficients[degree] * place;
        place *= GAO_FIELD;
    }
    return result;
}

int64_t gao_rs_decode(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 11) return -1;
    const int64_t n_value = input[0];
    const int64_t k_value = input[1];
    const int64_t t_value = input[2];
    if (n_value < 2 || n_value > GAO_MAX_N || k_value < 1 || k_value > GAO_MAX_K
        || k_value > n_value || t_value < 0 || t_value > GAO_MAX_T
        || 2 * t_value > n_value - k_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t k = (size_t)k_value;
    const size_t errors = (size_t)t_value;
    if (length != 3 + n) return -1;
    int64_t received[GAO_MAX_N] = {0};
    for (size_t index = 0; index < n; ++index) {
        const int64_t symbol = input[3 + index];
        if (symbol < 0 || symbol >= GAO_FIELD) return -1;
        received[index] = symbol;
    }
    return gao_decode(n, k, errors, received);
}

#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_LENGTH = 6, MAX_INPUT = 14, CAPACITY = 16 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t power_mod(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
    }
    return result;
}

static size_t trim(int64_t *polynomial, size_t length) {
    while (length > 0 && polynomial[length - 1] == 0) --length;
    return length;
}

static void divide_polynomials(const int64_t *dividend, size_t dividend_length,
                               const int64_t *divisor, size_t divisor_length,
                               int64_t *quotient, size_t *quotient_length,
                               int64_t *remainder, size_t *remainder_length) {
    for (size_t i = 0; i < CAPACITY; ++i) {
        quotient[i] = 0;
        remainder[i] = 0;
    }
    for (size_t i = 0; i < dividend_length; ++i) remainder[i] = dividend[i];
    *remainder_length = trim(remainder, dividend_length);
    if (*remainder_length >= divisor_length) {
        const int64_t inverse_lead = power_mod(divisor[divisor_length - 1], MODULUS - 2);
        while (*remainder_length >= divisor_length) {
            const size_t shift = *remainder_length - divisor_length;
            const int64_t factor = remainder[*remainder_length - 1] * inverse_lead % MODULUS;
            quotient[shift] = factor;
            for (size_t j = 0; j < divisor_length; ++j) {
                int64_t value = (remainder[shift + j] - factor * divisor[j]) % MODULUS;
                if (value < 0) value += MODULUS;
                remainder[shift + j] = value;
            }
            *remainder_length = trim(remainder, *remainder_length);
        }
    }
    *quotient_length = trim(quotient, dividend_length >= divisor_length
        ? dividend_length - divisor_length + 1 : 0);
}

static void multiply_polynomials(const int64_t *left, size_t left_length,
                                 const int64_t *right, size_t right_length,
                                 int64_t *product, size_t *product_length) {
    for (size_t i = 0; i < CAPACITY; ++i) product[i] = 0;
    if (left_length == 0 || right_length == 0) {
        *product_length = 0;
        return;
    }
    for (size_t i = 0; i < left_length; ++i) {
        for (size_t j = 0; j < right_length && i + j < CAPACITY; ++j) {
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    const size_t bound = left_length + right_length - 1 < CAPACITY
        ? left_length + right_length - 1 : CAPACITY;
    *product_length = trim(product, bound);
}

static void subtract_polynomials(const int64_t *left, size_t left_length,
                                 const int64_t *right, size_t right_length,
                                 int64_t *difference, size_t *difference_length) {
    const size_t bound = left_length > right_length ? left_length : right_length;
    for (size_t i = 0; i < CAPACITY; ++i) difference[i] = 0;
    for (size_t i = 0; i < bound; ++i) {
        const int64_t a = i < left_length ? left[i] : 0;
        const int64_t b = i < right_length ? right[i] : 0;
        difference[i] = (a - b + MODULUS) % MODULUS;
    }
    *difference_length = trim(difference, bound);
}

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t inv_of_polynomials(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    int64_t f[CAPACITY] = {0};
    int64_t g[CAPACITY] = {0};
    for (size_t i = 0; i < n; ++i) {
        f[i] = input[2 + i];
        if (f[i] < 0 || f[i] >= MODULUS) return -1;
    }
    for (size_t i = 0; i < m; ++i) {
        g[i] = input[2 + n + i];
        if (g[i] < 0 || g[i] >= MODULUS) return -1;
    }
    if (f[n - 1] == 0 || g[m - 1] == 0) return -1;

    int64_t inverse[CAPACITY] = {0};
    size_t inverse_length = 0;
    if (m > 1) {
        int64_t r0[CAPACITY] = {0};
        int64_t r1[CAPACITY] = {0};
        int64_t s0[CAPACITY] = {0};
        int64_t s1[CAPACITY] = {0};
        int64_t ignored_q[CAPACITY] = {0};
        int64_t initial_remainder[CAPACITY] = {0};
        size_t ignored_q_length = 0;
        size_t r1_length = 0;
        divide_polynomials(f, n, g, m, ignored_q, &ignored_q_length,
                           initial_remainder, &r1_length);
        memcpy(r0, g, m * sizeof(int64_t));
        memcpy(r1, initial_remainder, r1_length * sizeof(int64_t));
        size_t r0_length = m;
        size_t s0_length = 0;
        size_t s1_length = 1;
        s1[0] = 1;

        while (r1_length > 0) {
            int64_t quotient[CAPACITY] = {0};
            int64_t remainder[CAPACITY] = {0};
            int64_t product[CAPACITY] = {0};
            int64_t next_s[CAPACITY] = {0};
            size_t quotient_length = 0;
            size_t remainder_length = 0;
            size_t product_length = 0;
            size_t next_s_length = 0;
            divide_polynomials(r0, r0_length, r1, r1_length,
                               quotient, &quotient_length, remainder, &remainder_length);
            multiply_polynomials(quotient, quotient_length, s1, s1_length,
                                 product, &product_length);
            subtract_polynomials(s0, s0_length, product, product_length,
                                 next_s, &next_s_length);

            memcpy(r0, r1, r1_length * sizeof(int64_t));
            r0_length = r1_length;
            memcpy(r1, remainder, remainder_length * sizeof(int64_t));
            r1_length = remainder_length;
            memcpy(s0, s1, s1_length * sizeof(int64_t));
            s0_length = s1_length;
            memcpy(s1, next_s, next_s_length * sizeof(int64_t));
            s1_length = next_s_length;
        }
        if (r0_length != 1) return -1;
        const int64_t scale = power_mod(r0[0], MODULUS - 2);
        for (size_t i = 0; i < s0_length; ++i) inverse[i] = s0[i] * scale % MODULUS;
        inverse_length = trim(inverse, s0_length);
    }

    const size_t bytes = 8 * inverse_length;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < inverse_length; ++i) store_le(output, 8 * i, inverse[i]);
    return (int64_t)bytes;
}

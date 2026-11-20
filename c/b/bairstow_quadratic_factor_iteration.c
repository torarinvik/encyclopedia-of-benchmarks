#include <stddef.h>
#include <stdint.h>

enum { MIN_DEGREE = 3, MAX_DEGREE = 8, MAX_ITERATIONS = 4,
       MAX_INPUT_LENGTH = 14, MAX_OUTPUT_BYTES = 88 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    base = normalize(base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bairstow_quadratic_factor_iteration(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t degree_value = input[0];
    if (degree_value < MIN_DEGREE || degree_value > MAX_DEGREE) return -1;
    const size_t degree = (size_t)degree_value;
    if (length != degree + 5) return -1;

    int64_t coefficients[MAX_DEGREE + 1] = {0};
    for (size_t i = 0; i <= degree; ++i) {
        coefficients[i] = input[1 + i];
        if (coefficients[i] < 0 || coefficients[i] >= MODULUS) return -1;
    }
    int64_t s_value = input[degree + 2];
    int64_t t_value = input[degree + 3];
    const int64_t iterations_value = input[degree + 4];
    if (coefficients[degree] == 0 || s_value < 0 || s_value >= MODULUS
            || t_value < 0 || t_value >= MODULUS
            || iterations_value < 1 || iterations_value > MAX_ITERATIONS) return -1;
    const size_t iterations = (size_t)iterations_value;

    int64_t s_trace[MAX_ITERATIONS + 1] = {0};
    int64_t t_trace[MAX_ITERATIONS + 1] = {0};
    s_trace[0] = s_value;
    t_trace[0] = t_value;
    for (size_t step = 0; step < iterations; ++step) {
        int64_t q[MAX_DEGREE + 2] = {0};
        int64_t r[MAX_DEGREE + 2] = {0};
        q[degree] = coefficients[degree];
        r[degree] = coefficients[degree];
        for (size_t cursor = degree; cursor-- > 0;) {
            q[cursor] = normalize(coefficients[cursor] + s_value * q[cursor + 1]
                                  + t_value * q[cursor + 2]);
            r[cursor] = normalize(q[cursor] + s_value * r[cursor + 1]
                                  + t_value * r[cursor + 2]);
        }
        const int64_t r2 = r[2], r3 = r[3], q0 = q[0], q1 = q[1];
        const int64_t ell = normalize(s_value * r2 + t_value * r3);
        const int64_t denominator = normalize(r2 * r2 - ell * r3);
        if (denominator == 0) return -1;
        const int64_t inverse = power(denominator, MODULUS - 2);
        const int64_t delta_s = normalize(r3 * q0 - r2 * q1) * inverse % MODULUS;
        const int64_t delta_t = normalize(ell * q1 - r2 * q0) * inverse % MODULUS;
        s_value = normalize(s_value + delta_s);
        t_value = normalize(t_value + delta_t);
        s_trace[step + 1] = s_value;
        t_trace[step + 1] = t_value;
    }

    const size_t output_bytes = 8 * (2 * iterations + 3);
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)(iterations + 1));
    for (size_t i = 0; i <= iterations; ++i) {
        store_i64_le(output, 8 * (1 + 2 * i), s_trace[i]);
        store_i64_le(output, 8 * (2 + 2 * i), t_trace[i]);
    }
    return (int64_t)output_bytes;
}

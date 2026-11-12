#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 11 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t power_mod(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t polynomial_interpolation_on_geometric_sequence(const int64_t *input, size_t length,
                                                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const int64_t a = input[1], r = input[2];
    if (length != 3 + n || a < 0 || a >= MODULUS || r < 0 || r >= MODULUS) return -1;

    int64_t points[MAX_N] = {0};
    int64_t differences[MAX_N] = {0};
    int64_t newton[MAX_N] = {0};
    int64_t point = a;
    for (size_t i = 0; i < n; ++i) {
        points[i] = point;
        differences[i] = input[3 + i];
        if (differences[i] < 0 || differences[i] >= MODULUS) return -1;
        for (size_t j = 0; j < i; ++j) if (points[i] == points[j]) return -1;
        point = point * r % MODULUS;
    }

    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    if (n == 0) return 0;
    newton[0] = differences[0];
    for (size_t order = 1; order < n; ++order) {
        const int64_t r_order = power_mod(r, (int64_t)order);
        for (size_t end = n; end > order; --end) {
            const size_t i = end - 1;
            const int64_t r_factor = power_mod(r, (int64_t)(i - order));
            int64_t denominator = a * r_factor % MODULUS;
            denominator = denominator * (r_order - 1) % MODULUS;
            const int64_t inverse = power_mod(normalize(denominator), MODULUS - 2);
            differences[i] = normalize((differences[i] - differences[i - 1]) * inverse);
        }
        newton[order] = differences[order];
    }

    int64_t coefficients[MAX_N] = {0};
    int64_t basis[MAX_N + 1] = {0};
    basis[0] = 1;
    size_t degree = 0;
    for (size_t order = 0; order < n; ++order) {
        for (size_t k = 0; k <= degree; ++k)
            coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % MODULUS;
        if (order + 1 == n) break;
        int64_t expanded[MAX_N + 1] = {0};
        for (size_t k = 0; k <= degree; ++k) {
            expanded[k] = normalize(expanded[k] - basis[k] * points[order]);
            expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
        }
        for (size_t k = 0; k <= degree + 1; ++k) basis[k] = expanded[k];
        ++degree;
    }
    for (size_t i = 0; i < n; ++i) store_le(output, 8 * i, coefficients[i]);
    return (int64_t)bytes;
}

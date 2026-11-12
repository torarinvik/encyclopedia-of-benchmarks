#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_INPUT = 25 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t conversion_from_monomial_basis_to_newton_basis(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;

    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t residual[MAX_N] = {0};
    int64_t answer[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) residual[i] = input[i + 1];

    size_t active = n;
    for (size_t i = 0; i < n; ++i) {
        const int64_t node = input[n + 1 + i];
        int64_t value = 0;
        for (size_t degree = active; degree > 0; --degree)
            value = (value * node + residual[degree - 1]) % MODULUS;
        answer[i] = value;
        if (active == 1) continue;

        int64_t quotient[MAX_N] = {0};
        quotient[active - 2] = residual[active - 1];
        for (size_t degree = active - 2; degree > 0; --degree)
            quotient[degree - 1] =
                (residual[degree] + node * quotient[degree]) % MODULUS;
        for (size_t degree = 0; degree + 1 < active; ++degree)
            residual[degree] = quotient[degree];
        --active;
    }
    for (size_t i = 0; i < n; ++i) store_le(output, 8 * i, answer[i]);
    return (int64_t)bytes;
}

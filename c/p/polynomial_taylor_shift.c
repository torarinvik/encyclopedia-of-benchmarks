#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT = 66 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t polynomial_taylor_shift(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const int64_t shift = input[1];
    if (length != n + 2 || shift < 0 || shift >= MODULUS) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;

    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t shifted[MAX_N] = {0};
    size_t processed = 0;
    for (size_t source = n; source > 0; --source) {
        for (size_t degree = processed; degree > 0; --degree)
            shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % MODULUS;
        shifted[0] = (shifted[0] * shift + input[source + 1]) % MODULUS;
        ++processed;
    }
    for (size_t i = 0; i < n; ++i) store_le(output, 8 * i, shifted[i]);
    return (int64_t)bytes;
}

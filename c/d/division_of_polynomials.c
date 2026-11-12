#include <stddef.h>
#include <stdint.h>

enum {
    MAX_N = 64,
    MAX_INPUT = 131,
    MAX_OUTPUT_BYTES = 536
};

static const int64_t MODULUS = INT64_C(998244353);

static int64_t power_mod(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static size_t trim(const int64_t *polynomial, size_t length)
{
    while (length > 0 && polynomial[length - 1] == 0) --length;
    return length;
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t division_of_polynomials(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + n + m) return -1;

    int64_t work[MAX_N] = {0};
    int64_t quotient[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        work[i] = input[2 + i];
        if (work[i] < 0 || work[i] >= MODULUS) return -1;
    }
    for (size_t i = 0; i < m; ++i)
        if (input[2 + n + i] < 0 || input[2 + n + i] >= MODULUS) return -1;
    if (work[n - 1] == 0 || input[2 + n + m - 1] == 0) return -1;

    size_t quotient_bound = 0;
    if (n >= m) {
        quotient_bound = n - m + 1;
        const int64_t inverse_leading = power_mod(input[2 + n + m - 1], MODULUS - 2);
        for (size_t shift_plus_one = quotient_bound; shift_plus_one > 0; --shift_plus_one) {
            const size_t shift = shift_plus_one - 1;
            const int64_t factor = work[shift + m - 1] * inverse_leading % MODULUS;
            quotient[shift] = factor;
            for (size_t j = 0; j < m; ++j) {
                int64_t value = (work[shift + j] - factor * input[2 + n + j]) % MODULUS;
                if (value < 0) value += MODULUS;
                work[shift + j] = value;
            }
        }
    }

    const size_t quotient_length = trim(quotient, quotient_bound);
    const size_t remainder_bound = n < m ? n : m;
    const size_t remainder_length = trim(work, remainder_bound);
    const size_t bytes = 8 * (2 + quotient_length + remainder_length);
    if (bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < bytes) return -2;

    store_le(output, 0, (int64_t)quotient_length);
    store_le(output, 8, (int64_t)remainder_length);
    size_t offset = 16;
    for (size_t i = 0; i < quotient_length; ++i, offset += 8)
        store_le(output, offset, quotient[i]);
    for (size_t i = 0; i < remainder_length; ++i, offset += 8)
        store_le(output, offset, work[i]);
    return (int64_t)bytes;
}

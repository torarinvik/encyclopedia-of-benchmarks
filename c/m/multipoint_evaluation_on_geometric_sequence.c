#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 8, NTT_SIZE = 32, MAX_INPUT = 12 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t mod_pow(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void ntt(int64_t values[NTT_SIZE], int inverse)
{
    size_t j = 0;
    for (size_t i = 1; i < NTT_SIZE; ++i) {
        size_t bit = NTT_SIZE / 2;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) { const int64_t swap = values[i]; values[i] = values[j]; values[j] = swap; }
    }
    for (size_t block = 2; block <= NTT_SIZE; block <<= 1) {
        int64_t root = mod_pow(3, (MODULUS - 1) / (int64_t)block);
        if (inverse) root = mod_pow(root, MODULUS - 2);
        const size_t half = block / 2;
        for (size_t start = 0; start < NTT_SIZE; start += block) {
            int64_t factor = 1;
            for (size_t offset = 0; offset < half; ++offset) {
                const int64_t even = values[start + offset];
                const int64_t odd = values[start + offset + half] * factor % MODULUS;
                values[start + offset] = (even + odd) % MODULUS;
                values[start + offset + half] = (even - odd + MODULUS) % MODULUS;
                factor = factor * root % MODULUS;
            }
        }
    }
    if (inverse) {
        const int64_t scale = mod_pow(NTT_SIZE, MODULUS - 2);
        for (size_t i = 0; i < NTT_SIZE; ++i) values[i] = values[i] * scale % MODULUS;
    }
}

static int64_t evaluate(const int64_t *coefficients, size_t count, int64_t x)
{
    int64_t value = 0;
    for (size_t i = count; i > 0; --i) value = (value * x + coefficients[i - 1]) % MODULUS;
    return value;
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t multipoint_evaluation_on_geometric_sequence(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    const int64_t start = input[2], ratio = input[3];
    if (length != n + 4 || start < 0 || start >= MODULUS || ratio < 0 || ratio >= MODULUS) return -1;
    for (size_t i = 0; i < n; ++i) if (input[4 + i] < 0 || input[4 + i] >= MODULUS) return -1;
    const size_t bytes = 8 * m;
    if (output == NULL || capacity < bytes) return -2;

    if (start == 0) {
        for (size_t i = 0; i < m; ++i) store_le(output, 8 * i, input[4]);
        return (int64_t)bytes;
    }
    if (ratio == 0) {
        store_le(output, 0, evaluate(input + 4, n, start));
        for (size_t i = 1; i < m; ++i) store_le(output, 8 * i, input[4]);
        return (int64_t)bytes;
    }

    int64_t left[NTT_SIZE] = {0}, right[NTT_SIZE] = {0};
    const int64_t inverse_ratio = mod_pow(ratio, MODULUS - 2);
    int64_t start_power = 1, inverse_chirp = 1, inverse_ratio_power = 1;
    for (size_t degree = 0; degree < n; ++degree) {
        left[n - 1 - degree] = input[4 + degree] * start_power % MODULUS * inverse_chirp % MODULUS;
        start_power = start_power * start % MODULUS;
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    int64_t chirp = 1, ratio_power = 1;
    for (size_t index = 0; index < n + m - 1; ++index) {
        right[index] = chirp;
        chirp = chirp * ratio_power % MODULUS;
        ratio_power = ratio_power * ratio % MODULUS;
    }
    ntt(left, 0);
    ntt(right, 0);
    for (size_t i = 0; i < NTT_SIZE; ++i) left[i] = left[i] * right[i] % MODULUS;
    ntt(left, 1);
    inverse_chirp = 1;
    inverse_ratio_power = 1;
    for (size_t i = 0; i < m; ++i) {
        store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % MODULUS);
        inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS;
    }
    return (int64_t)bytes;
}

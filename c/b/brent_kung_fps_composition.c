#include <stddef.h>
#include <stdint.h>

enum {
    MODULUS = 998244353,
    MAX_N = 32,
    MAX_INPUT = 66,
    MAX_BLOCKS = 6,
    MAX_POWERS = 7
};

static void multiply_truncated(const int64_t *left, const int64_t *right,
                              int64_t *product, size_t n)
{
    for (size_t degree = 0; degree < n; ++degree) product[degree] = 0;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n - i; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
    }
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t brent_kung_fps_composition(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1 + n] != 0) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    const size_t block_count = (n + block_size - 1) / block_size;
    int64_t powers[MAX_POWERS][MAX_N] = {{0}};
    int64_t blocks[MAX_BLOCKS][MAX_N] = {{0}};
    int64_t temporary[MAX_N] = {0};
    int64_t composed[MAX_N] = {0};
    powers[0][0] = 1;

    for (size_t exponent = 1; exponent <= block_size; ++exponent) {
        multiply_truncated(powers[exponent - 1], input + 1 + n, temporary, n);
        for (size_t degree = 0; degree < n; ++degree)
            powers[exponent][degree] = temporary[degree];
    }
    for (size_t block = 0; block < block_count; ++block) {
        for (size_t offset = 0; offset < block_size; ++offset) {
            const size_t coefficient_index = block * block_size + offset;
            if (coefficient_index >= n) break;
            const int64_t coefficient = input[1 + coefficient_index];
            for (size_t degree = 0; degree < n; ++degree)
                blocks[block][degree] =
                    (blocks[block][degree] + coefficient * powers[offset][degree]) % MODULUS;
        }
    }

    for (size_t degree = 0; degree < n; ++degree)
        composed[degree] = blocks[block_count - 1][degree];
    for (size_t block = block_count - 1; block > 0; --block) {
        multiply_truncated(composed, powers[block_size], temporary, n);
        for (size_t degree = 0; degree < n; ++degree)
            composed[degree] = (temporary[degree] + blocks[block - 1][degree]) % MODULUS;
    }

    for (size_t degree = 0; degree < n; ++degree)
        store_le(output, 8 * degree, composed[degree]);
    return (int64_t)bytes;
}

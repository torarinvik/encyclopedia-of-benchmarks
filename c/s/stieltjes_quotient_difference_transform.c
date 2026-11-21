#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MIN_N 2
#define MAX_N 9
#define MAX_WORDS 11u
#define TABLE_COLUMNS 9
#define OUTPUT_BYTES 80u

static int64_t stieltjes_mod(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t stieltjes_mul(int64_t left, int64_t right)
{
    return (left * right) % MODULUS;
}

static int64_t stieltjes_power(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = stieltjes_mul(result, base);
        base = stieltjes_mul(base, base);
        exponent >>= 1;
    }
    return result;
}

static void stieltjes_store_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t stieltjes_quotient_difference_transform(
    const int64_t *input, size_t input_length,
    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_WORDS) return -1;
    const int64_t n0 = input[0];
    if (n0 < MIN_N || n0 > MAX_N || input_length != (size_t)n0 + 1) return -1;
    const size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] <= 0 || input[i + 1] >= MODULUS) return -1;

    int64_t q[5][TABLE_COLUMNS] = {{0}};
    int64_t e[5][TABLE_COLUMNS] = {{0}};
    for (size_t k = 0; k + 1 < n; ++k)
        q[1][k] = stieltjes_mul(input[k + 2], stieltjes_power(input[k + 1], MODULUS - 2));

    for (int j = 1; j <= 4; ++j) {
        const int last_e = (int)n - 2 * j - 1;
        if (last_e < 0) break;
        for (int k = 0; k <= last_e; ++k)
            e[j][k] = stieltjes_mod(e[j - 1][k + 1] + q[j][k + 1] - q[j][k]);

        const int last_q = (int)n - 2 * j - 2;
        if (last_q >= 0) {
            for (int k = 0; k <= last_q; ++k) {
                const int64_t pivot = e[j][k];
                if (pivot == 0) return -1;
                int64_t product = stieltjes_mul(q[j][k + 1], e[j][k + 1]);
                q[j + 1][k] = stieltjes_mul(product, stieltjes_power(pivot, MODULUS - 2));
            }
        }
    }

    const size_t required = 8 * (n + 1);
    if (output == NULL || output_capacity < required) return -2;
    const int64_t first_coefficient = input[1];
    stieltjes_store_i64(output, 0, (int64_t)n);
    stieltjes_store_i64(output, 8, first_coefficient);
    for (size_t index = 1; index < n; ++index) {
        const int row = (int)((index + 1) / 2);
        const int64_t value = (index & 1) ? q[row][0] : e[index / 2][0];
        stieltjes_store_i64(output, 8 * (index + 1), value);
    }
    return (int64_t)required;
}

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_HEIGHT = 32, MAX_WIDTH = 32, MAX_QUERIES = 128,
       MAX_INPUT_LENGTH = 1540, MAX_OUTPUT_BYTES = 1024 };
static const int64_t MODULUS = INT64_C(1000000007);
static const int64_t ROW_BASE = 31;
static const int64_t COLUMN_BASE = 37;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rolling_hash_2d_rectangle_query(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t h_value = input[0], w_value = input[1], q_value = input[2];
    if (h_value < 1 || h_value > MAX_HEIGHT || w_value < 1 || w_value > MAX_WIDTH ||
        q_value < 1 || q_value > MAX_QUERIES) return -1;
    const size_t h = (size_t)h_value, w = (size_t)w_value, q = (size_t)q_value;
    if (length != 3 + h * w + 4 * q) return -1;
    const size_t query_offset = 3 + h * w;
    for (size_t i = 0; i < h * w; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 255) return -1;
    for (size_t i = 0; i < q; ++i) {
        const int64_t r0 = input[query_offset + 4 * i];
        const int64_t c0 = input[query_offset + 4 * i + 1];
        const int64_t r1 = input[query_offset + 4 * i + 2];
        const int64_t c1 = input[query_offset + 4 * i + 3];
        if (r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value) return -1;
    }
    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;

    int64_t row_power[MAX_HEIGHT + 1] = {1};
    int64_t col_power[MAX_WIDTH + 1] = {1};
    for (size_t i = 1; i <= h; ++i) row_power[i] = row_power[i - 1] * ROW_BASE % MODULUS;
    for (size_t j = 1; j <= w; ++j) col_power[j] = col_power[j - 1] * COLUMN_BASE % MODULUS;
    int64_t prefix[MAX_HEIGHT + 1][MAX_WIDTH + 1] = {{0}};
    for (size_t r = 1; r <= h; ++r) {
        int64_t row_hash = 0;
        for (size_t c = 1; c <= w; ++c) {
            row_hash = (row_hash * COLUMN_BASE + input[3 + (r - 1) * w + c - 1]) % MODULUS;
            prefix[r][c] = (prefix[r - 1][c] * ROW_BASE + row_hash) % MODULUS;
        }
    }

    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < q; ++i) {
        const size_t r0 = (size_t)input[query_offset + 4 * i];
        const size_t c0 = (size_t)input[query_offset + 4 * i + 1];
        const size_t r1 = (size_t)input[query_offset + 4 * i + 2];
        const size_t c1 = (size_t)input[query_offset + 4 * i + 3];
        const size_t rh = r1 - r0, cw = c1 - c0;
        int64_t value = prefix[r1][c1]
            - prefix[r0][c1] * row_power[rh] % MODULUS
            - prefix[r1][c0] * col_power[cw] % MODULUS
            + prefix[r0][c0] * row_power[rh] % MODULUS * col_power[cw] % MODULUS;
        value %= MODULUS;
        if (value < 0) value += MODULUS;
        store_i64_le(staged, 8 * i, value);
    }
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}

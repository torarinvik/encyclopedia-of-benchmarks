#include <stddef.h>
#include <stdint.h>

#define MAX_ORDER INT64_C(8)

static int64_t hilbert_index(int64_t order, int64_t x, int64_t y) {
    int64_t current_x = x;
    int64_t current_y = y;
    int64_t distance = 0;
    for (int64_t bit_index = order - 1; bit_index >= 0; --bit_index) {
        const int64_t bit = INT64_C(1) << bit_index;
        const int64_t x_bit = (current_x & bit) != 0;
        const int64_t y_bit = (current_y & bit) != 0;
        distance += bit * bit * ((3 * x_bit) ^ y_bit);

        const int64_t mask = bit - 1;
        int64_t low_x = current_x & mask;
        int64_t low_y = current_y & mask;
        if (y_bit == 0) {
            if (x_bit != 0) {
                low_x = mask - low_x;
                low_y = mask - low_y;
            }
            current_x = low_y;
            current_y = low_x;
        } else {
            current_x = low_x;
            current_y = low_y;
        }
    }
    return distance;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t hilbert_curve_index_encode(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t order = input[0];
    if (order < 1 || order > MAX_ORDER) return -1;
    const int64_t side = INT64_C(1) << order;
    const int64_t x = input[1];
    const int64_t y = input[2];
    if (x < 0 || x >= side || y < 0 || y >= side) return -1;
    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, hilbert_index(order, x, y));
    return 8;
}

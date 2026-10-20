#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 256

static uint32_t spread_16(uint32_t value) {
    value = (value | (value << 8)) & UINT32_C(0x00ff00ff);
    value = (value | (value << 4)) & UINT32_C(0x0f0f0f0f);
    value = (value | (value << 2)) & UINT32_C(0x33333333);
    return (value | (value << 1)) & UINT32_C(0x55555555);
}

static uint32_t morton_code(uint32_t x, uint32_t y) {
    return spread_16(x) | (spread_16(y) << 1);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t morton_sort(const int64_t *input, size_t length,
                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || input[0] < 1 || input[0] > MAX_POINTS) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + 2 * count) return -1;

    uint32_t keys[MAX_POINTS];
    size_t order[MAX_POINTS];
    for (size_t index = 0; index < count; ++index) {
        const int64_t x = input[1 + 2 * index];
        const int64_t y = input[2 + 2 * index];
        if (x < 0 || x > 65535 || y < 0 || y > 65535) return -1;
        keys[index] = morton_code((uint32_t)x, (uint32_t)y);
        order[index] = index;
    }
    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 1; index < count; ++index) {
        const size_t current = order[index];
        size_t position = index;
        while (position > 0 &&
               (keys[order[position - 1]] > keys[current] ||
                (keys[order[position - 1]] == keys[current] && order[position - 1] > current))) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    for (size_t index = 0; index < count; ++index) {
        store_i64_le(output, index * 8, (int64_t)order[index]);
    }
    return (int64_t)output_bytes;
}

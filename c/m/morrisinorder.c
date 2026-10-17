/* Bounded Morris inorder traversal over a complete level-order tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 63
#define MAX_PARSEABLE_INPUT_LENGTH 65

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t morrisinorder(const int64_t *values, size_t length,
                      uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_NODE_COUNT) return -1;
    const size_t count = (size_t)raw_count;
    if (length != count + 1) return -1;
    for (size_t index = 0; index < count; ++index)
        if (values[index + 1] < INT32_MIN || values[index + 1] > INT32_MAX) return -1;

    const size_t byte_count = 4 * count;
    if (output == NULL || capacity < byte_count) return -2;

    int left[MAX_NODE_COUNT];
    int right[MAX_NODE_COUNT];
    for (size_t index = 0; index < count; ++index) {
        const size_t left_index = 2 * index + 1;
        const size_t right_index = 2 * index + 2;
        left[index] = left_index < count ? (int)left_index : -1;
        right[index] = right_index < count ? (int)right_index : -1;
    }

    int current = count == 0 ? -1 : 0;
    size_t written = 0;
    while (current >= 0) {
        if (left[current] < 0) {
            store_i32_le(output, 4 * written, (int32_t)values[1 + (size_t)current]);
            ++written;
            current = right[current];
        } else {
            int predecessor = left[current];
            while (right[predecessor] >= 0 && right[predecessor] != current)
                predecessor = right[predecessor];
            if (right[predecessor] < 0) {
                right[predecessor] = current;
                current = left[current];
            } else {
                right[predecessor] = -1;
                store_i32_le(output, 4 * written, (int32_t)values[1 + (size_t)current]);
                ++written;
                current = right[current];
            }
        }
    }
    return (int64_t)byte_count;
}

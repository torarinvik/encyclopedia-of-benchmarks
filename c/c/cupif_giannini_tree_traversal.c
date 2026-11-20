#include <stddef.h>
#include <stdint.h>

int64_t cupif_giannini_tree_traversal(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 3) return -1;
    if (length != 2) return -1;

    const int64_t height = input[0];
    const int64_t key_value = input[1];
    if (height < 0 || height > 6) return -1;
    const uint64_t leaf_count = UINT64_C(1) << (unsigned)height;
    if (key_value < 0 || (uint64_t)key_value >= leaf_count) return -1;
    if (output == NULL || capacity < (size_t)leaf_count) return -2;

    for (uint64_t count = 0; count < leaf_count; ++count) {
        const uint64_t path = count ^ (uint64_t)key_value;
        uint8_t leaf_code = 0;
        for (unsigned depth = 0; depth < (unsigned)height; ++depth) {
            if (((path >> depth) & 1U) != 0) {
                leaf_code |= (uint8_t)(1U << depth);
            }
        }
        output[count] = leaf_code;
    }
    return (int64_t)leaf_count;
}

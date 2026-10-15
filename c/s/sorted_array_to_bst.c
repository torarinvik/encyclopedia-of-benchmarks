/* Build a height-balanced BST from sorted unique keys and serialize it. */
#include <stddef.h>
#include <stdint.h>

static size_t emit_tree(const int64_t *values, size_t start, size_t end,
                        uint8_t *output, size_t position)
{
    if (start == end) { output[position] = 0; return position + 1; }
    const size_t middle = start + (end - start - 1) / 2;
    output[position++] = 1;
    const uint32_t encoded = (uint32_t)(int32_t)values[middle];
    output[position++] = (uint8_t)encoded;
    output[position++] = (uint8_t)(encoded >> 8);
    output[position++] = (uint8_t)(encoded >> 16);
    output[position++] = (uint8_t)(encoded >> 24);
    position = emit_tree(values, start, middle, output, position);
    return emit_tree(values, middle + 1, end, output, position);
}

int64_t sorted_array_to_bst(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (length > 64) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX ||
            (index > 0 && values[index - 1] >= values[index])) return -1;
    }
    const size_t required = 6 * length + 1;
    if (output_capacity < required || output == NULL) return -2;
    (void)emit_tree(values, 0, length, output, 0);
    return (int64_t)length;
}

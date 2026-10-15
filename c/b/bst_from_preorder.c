/* Validate and serialize a strict BST reconstructed from preorder values. */
#include <stddef.h>
#include <stdint.h>

static int valid_preorder(const int64_t *values, size_t start, size_t end,
                          int64_t lower, int64_t upper)
{
    if (start == end) return 1;
    const int64_t root = values[start];
    if (root <= lower || root >= upper) return 0;
    size_t split = start + 1;
    while (split < end && values[split] < root) ++split;
    return valid_preorder(values, start + 1, split, lower, root) &&
           valid_preorder(values, split, end, root, upper);
}

static size_t emit_preorder_tree(const int64_t *values, size_t start, size_t end,
                                 uint8_t *output, size_t position)
{
    if (start == end) {
        output[position] = 0;
        return position + 1;
    }
    const int64_t root = values[start];
    size_t split = start + 1;
    while (split < end && values[split] < root) ++split;
    output[position++] = 1;
    const uint32_t encoded = (uint32_t)(int32_t)root;
    output[position++] = (uint8_t)(encoded & 255u);
    output[position++] = (uint8_t)((encoded >> 8) & 255u);
    output[position++] = (uint8_t)((encoded >> 16) & 255u);
    output[position++] = (uint8_t)(encoded >> 24);
    position = emit_preorder_tree(values, start + 1, split, output, position);
    return emit_preorder_tree(values, split, end, output, position);
}

int64_t bst_from_preorder(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > 15) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    if (!valid_preorder(values, 0, length, (int64_t)INT32_MIN - 1, (int64_t)INT32_MAX + 1)) return -1;
    const size_t required = 6 * length + 1;
    if (output_capacity < required || output == NULL) return -2;
    (void)emit_preorder_tree(values, 0, length, output, 0);
    return (int64_t)length;
}

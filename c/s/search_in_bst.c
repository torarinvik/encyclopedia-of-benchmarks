/* Follow the unique BST branch until the target node or an empty child. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 5000
#define MAX_VALUE 10000000

int64_t search_in_bst(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return -1;
    const int64_t count_value = input[0];
    const int64_t root = input[1];
    const int64_t target = input[2];
    if (count_value < 0 || count_value > MAX_NODE_COUNT ||
        length != 3 + 3 * (size_t)count_value || target < 1 || target > MAX_VALUE) return -1;
    const size_t count = (size_t)count_value;
    if (count == 0) return root == -1 ? -1 : -1;
    if (root < 0 || (uint64_t)root >= count) return -1;
    int64_t node = root;
    while (node != -1) {
        if (node < 0 || (uint64_t)node >= count) return -1;
        const size_t offset = 3 + 3 * (size_t)node;
        const int64_t value = input[offset];
        const int64_t left = input[offset + 1], right = input[offset + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= count) ||
            (right >= 0 && (uint64_t)right >= count)) return -1;
        if (value == target) return node;
        node = target < value ? left : right;
    }
    return -1;
}

#include <stddef.h>
#include <stdint.h>

#define MAX_SLOTS 255
#define MISSING_NODE (-INT64_C(2147483648) - 1)

int64_t binary_tree_is_sorted_local(const int64_t *nodes, size_t length)
{
    if (length == 0 || length > MAX_SLOTS || nodes == NULL || nodes[0] == MISSING_NODE) return -1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = nodes[index];
        if (value == MISSING_NODE) continue;
        if (value < -INT64_C(2147483648) || value > INT64_C(2147483647)) return -1;
        if (index > 0) {
            const size_t parent = (index - 1) / 2;
            if (nodes[parent] == MISSING_NODE) return -1;
            if ((index % 2 == 1 && value > nodes[parent]) ||
                (index % 2 == 0 && value < nodes[parent])) return 0;
        }
    }
    return 1;
}

/* Eagerly materialize a BST's in-order sequence, then consume it through an iterator. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define VALUE_OFFSET INT64_C(100001)

int64_t bst_iterator(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;

    int64_t iterator_values[MAX_NODE_COUNT];
    size_t stack[MAX_NODE_COUNT];
    size_t top = 0, value_count = 0;
    int64_t current = root_index;
    while (current != -1 || top != 0) {
        while (current != -1) {
            if (current < 0 || (uint64_t)current >= node_count || top >= node_count) return -1;
            const size_t index = (size_t)current;
            const int64_t left = nodes[3 * index + 1];
            const int64_t right = nodes[3 * index + 2];
            if (left < -1 || (left >= 0 && (uint64_t)left >= node_count) ||
                right < -1 || (right >= 0 && (uint64_t)right >= node_count)) return -1;
            stack[top++] = index;
            current = left;
        }
        const size_t index = stack[--top];
        if (value_count >= node_count) return -1;
        const int64_t value = nodes[3 * index];
        if (value < -100000 || value > 100000 ||
            (value_count != 0 && iterator_values[value_count - 1] >= value)) return -1;
        iterator_values[value_count++] = value;
        current = nodes[3 * index + 2];
    }
    if (value_count != node_count) return -1;

    int64_t checksum = 0;
    size_t next_index = 0;
    while (next_index < value_count) {
        /* hasNext() is true here; next() returns the next materialized value. */
        checksum += ((int64_t)next_index + 1) * (iterator_values[next_index] + VALUE_OFFSET);
        ++next_index;
    }
    /* The iterator's final hasNext() call is false. */
    return checksum;
}

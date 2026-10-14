/* Binary-search-tree sort with iterative insertion and in-order traversal. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

void tree_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return;
    int64_t keys[MAX_VALUES];
    size_t left[MAX_VALUES], right[MAX_VALUES], stack[MAX_VALUES];
    const size_t empty = length;
    size_t root = empty;
    for (size_t index = 0; index < length; ++index) {
        keys[index] = values[index];
        left[index] = right[index] = empty;
        if (root == empty) {
            root = index;
            continue;
        }
        size_t node = root;
        for (;;) {
            size_t *child = keys[index] < keys[node] ? &left[node] : &right[node];
            if (*child == empty) { *child = index; break; }
            node = *child;
        }
    }
    size_t current = root, stack_size = 0, output = 0;
    while (current != empty || stack_size > 0) {
        while (current != empty) { stack[stack_size++] = current; current = left[current]; }
        current = stack[--stack_size];
        values[output++] = keys[current];
        current = right[current];
    }
}

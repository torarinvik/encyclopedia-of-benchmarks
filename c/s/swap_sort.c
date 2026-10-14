/* Count minimum swaps needed to order a distinct-value array. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256

static int position_less(const int64_t *keys, const size_t *order, size_t left, size_t right)
{
    const size_t left_index = order[left];
    const size_t right_index = order[right];
    return keys[left_index] < keys[right_index] ||
           (keys[left_index] == keys[right_index] && left_index < right_index);
}

static void sift_down(const int64_t *keys, size_t *order, size_t heap_length, size_t root)
{
    while (root < heap_length / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < heap_length && position_less(keys, order, child, child + 1)) ++child;
        if (!position_less(keys, order, root, child)) break;
        const size_t temporary = order[root];
        order[root] = order[child];
        order[child] = temporary;
        root = child;
    }
}

int64_t swap_sort(const int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return -1;
    int64_t keys[MAX_VALUES];
    size_t order[MAX_VALUES];
    unsigned char visited[MAX_VALUES] = {0};
    for (size_t index = 0; index < length; ++index) {
        keys[index] = values[index];
        order[index] = index;
    }
    for (size_t start = length / 2; start > 0;) {
        --start;
        sift_down(keys, order, length, start);
    }
    for (size_t end = length; end > 1;) {
        --end;
        const size_t temporary = order[0];
        order[0] = order[end];
        order[end] = temporary;
        sift_down(keys, order, end, 0);
    }
    for (size_t index = 1; index < length; ++index) {
        if (keys[order[index - 1]] == keys[order[index]]) return -1;
    }
    size_t swaps = 0;
    for (size_t start = 0; start < length; ++start) {
        if (visited[start]) continue;
        size_t node = start;
        size_t cycle_length = 0;
        while (!visited[node]) {
            visited[node] = 1;
            node = order[node];
            ++cycle_length;
        }
        if (cycle_length > 0) swaps += cycle_length - 1;
    }
    return (int64_t)swaps;
}

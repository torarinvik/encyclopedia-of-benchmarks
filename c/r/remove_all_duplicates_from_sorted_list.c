/* Recursively unlink every node in a repeated-value run. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 1024

static size_t remove_duplicate_runs(const int64_t *input, size_t *next_node,
                                    size_t node, size_t none)
{
    if (node == none) return none;
    const size_t next = next_node[node];
    if (next != none && input[node] == input[next]) {
        const int64_t duplicate = input[node];
        size_t after_run = next;
        while (after_run != none && input[after_run] == duplicate)
            after_run = next_node[after_run];
        return remove_duplicate_runs(input, next_node, after_run, none);
    }
    next_node[node] = remove_duplicate_runs(input, next_node, next, none);
    return node;
}

int64_t remove_all_duplicates_from_sorted_list(const int64_t *input, size_t length,
                                               uint8_t *output, size_t output_capacity)
{
    if (length > MAX_NODES || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (value < INT32_MIN || value > INT32_MAX
            || (index != 0 && input[index - 1] > value)) return -1;
    }
    size_t next_node[MAX_NODES + 1];
    for (size_t index = 0; index < length; ++index) next_node[index] = index + 1;
    next_node[length] = length;
    const size_t head = remove_duplicate_runs(input, next_node, 0, length);
    size_t survivor_count = 0;
    for (size_t node = head; node != length; node = next_node[node]) ++survivor_count;
    const size_t output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t node = head; node != length; node = next_node[node]) {
        const uint32_t bits = (uint32_t)(int32_t)input[node];
        for (size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? (int64_t)written : -1;
}

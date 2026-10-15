/* Recursively unlink every node whose signed 32-bit value matches the target. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 1024
#define NONE ((size_t)MAX_NODES)

static size_t remove_chain(const int64_t *input, size_t *next_node, size_t node,
                           size_t none, int64_t target)
{
    if (node == none) return none;
    const size_t next = next_node[node];
    if (input[node + 1] == target)
        return remove_chain(input, next_node, next, none, target);
    next_node[node] = remove_chain(input, next_node, next, none, target);
    return node;
}

int64_t remove_linked_list_elements(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > MAX_NODES + 1) return -1;
    const int64_t target = input[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    const size_t node_count = length - 1;
    size_t next_node[MAX_NODES];
    for (size_t index = 0; index < node_count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        next_node[index] = index + 1;
    }
    const size_t none = node_count;
    if (node_count < MAX_NODES) next_node[node_count] = none;
    size_t head = node_count == 0 ? none : 0;
    head = remove_chain(input, next_node, head, none, target);

    size_t survivor_count = 0;
    for (size_t node = head; node != none; node = next_node[node]) ++survivor_count;
    const size_t output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t node = head; node != none; node = next_node[node]) {
        const uint32_t bits = (uint32_t)(int32_t)input[node + 1];
        for (size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? (int64_t)written : -1;
}

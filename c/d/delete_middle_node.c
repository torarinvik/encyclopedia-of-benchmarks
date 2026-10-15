/* Delete the floor(n / 2)-indexed node using the source's fast/slow traversal. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 1024

int64_t delete_middle_node(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (length > MAX_NODES || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    if (length <= 1) return 0;

    size_t next_node[MAX_NODES + 1];
    for (size_t index = 0; index < length; ++index) next_node[index] = index + 1;
    next_node[length] = length;
    size_t node_count = 0;
    for (size_t cursor = 0; cursor != length; cursor = next_node[cursor]) ++node_count;
    size_t fast = 0, slow = 0, previous = length;
    while (next_node[fast] != length && next_node[next_node[fast]] != length) {
        previous = slow;
        slow = next_node[slow];
        fast = next_node[next_node[fast]];
    }
    if (node_count % 2 == 0) {
        previous = slow;
        slow = next_node[slow];
    }
    next_node[previous] = next_node[slow];

    const size_t survivor_count = node_count - 1;
    const size_t output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t node = 0; node != length; node = next_node[node]) {
        const uint32_t bits = (uint32_t)(int32_t)input[node];
        for (size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? (int64_t)written : -1;
}

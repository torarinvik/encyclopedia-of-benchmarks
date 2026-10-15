/* Remove a node by one-based distance from the tail in an index-based list. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIST_LENGTH 1024
#define NONE ((size_t)MAX_LIST_LENGTH)

int64_t remove_nth_node_from_end_of_list(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_LIST_LENGTH + 1) return -1;
    const size_t list_length = length - 1;
    for (size_t index = 0; index < list_length; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
    if (input[0] < 1 || (uint64_t)input[0] > list_length) return -1;

    size_t next_node[MAX_LIST_LENGTH];
    for (size_t index = 0; index < list_length; ++index)
        next_node[index] = index + 1 < list_length ? index + 1 : NONE;

    size_t node = 0, counted = 0;
    while (node != NONE) {
        node = next_node[node];
        ++counted;
    }
    if (counted != list_length) return -1;

    const size_t steps_to_target = counted - (size_t)input[0];
    size_t before = NONE;
    node = 0;
    for (size_t step = 0; step < steps_to_target; ++step) {
        before = node;
        node = next_node[node];
    }
    const size_t head = before == NONE ? next_node[node] : 0;
    if (before != NONE) next_node[before] = next_node[node];

    const size_t output_count = counted - 1;
    const size_t output_bytes = output_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    node = head;
    size_t written = 0;
    while (node != NONE) {
        const uint32_t bits = (uint32_t)(int32_t)input[node + 1];
        for (size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = (uint8_t)(bits >> (byte * 8));
        node = next_node[node];
        ++written;
    }
    return written == output_count ? (int64_t)written : -1;
}

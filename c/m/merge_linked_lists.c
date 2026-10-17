#include <stddef.h>
#include <stdint.h>

#define MAX_LIST_LENGTH 32
#define MAX_TOTAL_NODES (2 * MAX_LIST_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (2 + MAX_TOTAL_NODES + 1)

typedef struct {
    int32_t value;
    int32_t next;
} Node;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t merge_linked_lists(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_first = values[0];
    const int64_t raw_second = values[1];
    if (raw_first < 0 || raw_first > MAX_LIST_LENGTH ||
        raw_second < 0 || raw_second > MAX_LIST_LENGTH) return -1;
    const size_t first_length = (size_t)raw_first;
    const size_t second_length = (size_t)raw_second;
    const size_t total = first_length + second_length;
    if (total > MAX_TOTAL_NODES || length != 2 + total) return -1;

    Node nodes[MAX_TOTAL_NODES];
    for (size_t index = 0; index < first_length; ++index) {
        const int64_t value = values[2 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        nodes[index].value = (int32_t)value;
        nodes[index].next = index + 1 < first_length ? (int32_t)(index + 1) : -1;
    }
    const size_t second_start = first_length;
    for (size_t index = 0; index < second_length; ++index) {
        const int64_t value = values[2 + first_length + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        const size_t node = second_start + index;
        nodes[node].value = (int32_t)value;
        nodes[node].next = index + 1 < second_length ? (int32_t)(node + 1) : -1;
    }

    int32_t head1 = first_length == 0 ? -1 : 0;
    const int32_t head2 = second_length == 0 ? -1 : (int32_t)second_start;
    int32_t temp1 = head1;
    int32_t temp2 = head2;
    int32_t holder2 = -1;
    while (temp1 != -1 && temp2 != -1) {
        const int32_t holder1 = nodes[temp1].next;
        nodes[temp1].next = temp2;
        if (holder1 != -1) {
            holder2 = nodes[temp2].next;
            nodes[temp2].next = holder1;
        }
        temp1 = holder1;
        temp2 = holder2;
    }

    size_t output_count = 0;
    for (int32_t node = head1; node != -1; node = nodes[node].next) {
        if (node < 0 || (size_t)node >= total || output_count >= total) return -1;
        ++output_count;
    }
    const size_t required = output_count * 8;
    if (output == NULL || output_capacity < required) return -2;

    int32_t node = head1;
    for (size_t index = 0; index < output_count; ++index) {
        store_i64_le(output, 8 * index, (int64_t)nodes[node].value);
        node = nodes[node].next;
    }
    return (int64_t)required;
}

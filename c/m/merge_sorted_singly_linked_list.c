#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 128
#define MAX_INPUT_LENGTH 130
#define MAX_OUTPUT_BYTES (12 * MAX_NODES)

typedef struct {
    int32_t value;
    int32_t next;
    int32_t origin;
    int32_t position;
} ListNode;

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t merge_sorted_singly_linked_list(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_NODES) return -1;
    const size_t len_a = (size_t)input[0];
    if (len_a > length - 2) return -1;
    const size_t len_b_pos = 1 + len_a;
    const int64_t raw_len_b = input[len_b_pos];
    if (raw_len_b < 0 || raw_len_b > MAX_NODES - (int64_t)len_a) return -1;
    const size_t len_b = (size_t)raw_len_b;
    const size_t total = len_a + len_b;
    if (length != 2 + total) return -1;

    ListNode nodes[MAX_NODES];
    for (size_t i = 0; i < len_a; ++i) {
        const int64_t raw = input[1 + i];
        if (raw < INT32_MIN || raw > INT32_MAX || (i > 0 && input[i] > raw)) return -1;
        nodes[i] = (ListNode){(int32_t)raw, i + 1 < len_a ? (int32_t)(i + 1) : -1, 0, (int32_t)i};
    }
    const size_t b_start = len_b_pos + 1;
    for (size_t i = 0; i < len_b; ++i) {
        const int64_t raw = input[b_start + i];
        if (raw < INT32_MIN || raw > INT32_MAX || (i > 0 && input[b_start + i - 1] > raw)) return -1;
        const size_t node = len_a + i;
        nodes[node] = (ListNode){(int32_t)raw, i + 1 < len_b ? (int32_t)(node + 1) : -1, 1, (int32_t)i};
    }

    int32_t head_a = len_a == 0 ? -1 : 0;
    int32_t head_b = len_b == 0 ? -1 : (int32_t)len_a;
    int32_t merged_head = -1, tail = -1;
    while (head_a >= 0 && head_b >= 0) {
        int32_t node;
        if (nodes[head_a].value <= nodes[head_b].value) {
            node = head_a;
            head_a = nodes[node].next;
        } else {
            node = head_b;
            head_b = nodes[node].next;
        }
        if (tail < 0) merged_head = node;
        else nodes[tail].next = node;
        tail = node;
    }
    const int32_t remainder = head_a >= 0 ? head_a : head_b;
    if (tail < 0) merged_head = remainder;
    else nodes[tail].next = remainder;

    const size_t bytes = 12 * total;
    if (bytes > MAX_OUTPUT_BYTES || output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    size_t written = 0;
    for (int32_t node = merged_head; node >= 0; node = nodes[node].next) {
        put_i32_le(buffer, written, nodes[node].value);
        put_i32_le(buffer, written + 4, nodes[node].origin);
        put_i32_le(buffer, written + 8, nodes[node].position);
        written += 12;
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}

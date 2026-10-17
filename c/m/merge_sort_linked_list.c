#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 128

static int32_t merge_nodes(const int32_t *values, int32_t *next, int32_t left, int32_t right) {
    if (left < 0) return right;
    if (right < 0) return left;
    if (values[left] <= values[right]) {
        next[left] = merge_nodes(values, next, next[left], right);
        return left;
    }
    next[right] = merge_nodes(values, next, left, next[right]);
    return right;
}

static int32_t merge_sort_nodes(const int32_t *values, int32_t *next, int32_t head) {
    if (head < 0 || next[head] < 0) return head;
    int32_t slow = head, fast = next[head];
    while (fast >= 0 && next[fast] >= 0) {
        slow = next[slow];
        fast = next[next[fast]];
    }
    const int32_t right_head = next[slow];
    next[slow] = -1;
    const int32_t left = merge_sort_nodes(values, next, head);
    const int32_t right = merge_sort_nodes(values, next, right_head);
    return merge_nodes(values, next, left, right);
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t merge_sort_linked_list(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > 1 + MAX_ITEMS) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_ITEMS) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + count) return -1;

    int32_t values[MAX_ITEMS] = {0};
    int32_t next[MAX_ITEMS] = {0};
    for (size_t i = 0; i < count; ++i) {
        if (input[1 + i] < INT32_MIN || input[1 + i] > INT32_MAX) return -1;
        values[i] = (int32_t)input[1 + i];
        for (size_t j = 0; j < i; ++j)
            if (values[j] == values[i]) return -1;
        next[i] = i + 1 < count ? (int32_t)(i + 1) : -1;
    }
    const int32_t head = merge_sort_nodes(values, next, count == 0 ? -1 : 0);
    const size_t required = 4 * count;
    if (output == NULL || output_capacity < required) return -2;
    int32_t node = head;
    for (size_t i = 0; i < count; ++i) {
        put_i32_le(output, i * 4, values[node]);
        node = next[node];
    }
    return (int64_t)required;
}

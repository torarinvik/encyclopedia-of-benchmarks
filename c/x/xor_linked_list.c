#include <stddef.h>
#include <stdint.h>

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t xor_linked_list(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 66) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > 64) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return -1;
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    }
    const size_t needed = 8 + 8 * count;
    if (output == NULL || capacity < needed) return -2;

    int64_t node_values[65] = {0};
    size_t both[65] = {0};
    size_t tail = 0;
    for (size_t i = 0; i < count; ++i) {
        const size_t node_id = i + 1;
        node_values[node_id] = input[i + 1];
        both[node_id] = tail;
        if (tail != 0) both[tail] ^= node_id;
        tail = node_id;
    }

    write_i64_le(output, 0, count_value);
    size_t out = 8, previous = 0, current = count == 0 ? 0 : 1;
    while (current != 0) {
        write_i64_le(output, out, node_values[current]);
        out += 8;
        const size_t next = previous ^ both[current];
        previous = current;
        current = next;
    }
    return (int64_t)needed;
}

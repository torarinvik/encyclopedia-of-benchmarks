#include <stddef.h>
#include <stdint.h>

#define MAX_ELEMENTS 16

static void insert_at_bottom(int64_t *items, size_t size, int64_t value) {
    if (size == 0) {
        items[0] = value;
        return;
    }
    const int64_t top = items[size - 1];
    insert_at_bottom(items, size - 1, value);
    items[size] = top;
}

static void reverse_recursive(int64_t *items, size_t size) {
    if (size == 0) return;
    const int64_t top = items[size - 1];
    reverse_recursive(items, size - 1);
    insert_at_bottom(items, size - 1, top);
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t reverse_stack(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_ELEMENTS || length != (size_t)raw_count + 1) return -1;
    const size_t count = (size_t)raw_count;
    int64_t items[MAX_ELEMENTS];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
        items[i] = input[i + 1];
    }
    const size_t bytes = (count + 1) * 8;
    if (output == NULL || capacity < bytes) return -2;
    reverse_recursive(items, count);
    put_i64_le(output, 0, raw_count);
    for (size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (i + 1), items[i]);
    return (int64_t)bytes;
}

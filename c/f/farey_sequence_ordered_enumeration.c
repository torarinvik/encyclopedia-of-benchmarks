#include <stddef.h>
#include <stdint.h>

#define MAX_ORDER INT64_C(32)

static int64_t farey_count(int64_t order) {
    int64_t a = 0, b = 1, c = 1, d = order;
    int64_t count = 1;
    for (;;) {
        ++count;
        if (c == d) break;
        const int64_t k = (order + b) / d;
        const int64_t next_c = k * c - a;
        const int64_t next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return count;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t farey_sequence_ordered_enumeration(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1) return -1;
    const int64_t order = input[0];
    if (order < 1 || order > MAX_ORDER) return -1;
    const int64_t count = farey_count(order);
    const size_t words = (size_t)(1 + 2 * count);
    const size_t required = words * 8;
    if (output == NULL || capacity < required) return -2;

    store_i64_le(output, 0, count);
    store_i64_le(output, 8, 0);
    store_i64_le(output, 16, 1);
    int64_t a = 0, b = 1, c = 1, d = order;
    size_t position = 24;
    for (;;) {
        store_i64_le(output, position, c);
        store_i64_le(output, position + 8, d);
        position += 16;
        if (c == d) break;
        const int64_t k = (order + b) / d;
        const int64_t next_c = k * c - a;
        const int64_t next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return (int64_t)required;
}

#include <stddef.h>
#include <stdint.h>

#define MAX_K 8
#define MAX_ITEMS 64
#define MAX_INPUT (2 + MAX_ITEMS)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t misra_gries_summaries(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t k64 = input[0], count64 = input[1];
    if (k64 < 1 || k64 > MAX_K || count64 < 0 || count64 > MAX_ITEMS ||
        length != (size_t)(2 + count64)) return -1;
    const size_t k = (size_t)k64, count = (size_t)count64;
    int64_t items[MAX_K], counts[MAX_K] = {0};
    for (size_t slot = 0; slot < k; ++slot) items[slot] = -1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t item = input[index + 2];
        if (item < 0 || item > 15) return -1;
        size_t slot = 0;
        while (slot < k && items[slot] != item) ++slot;
        if (slot < k) { ++counts[slot]; continue; }
        slot = 0;
        while (slot < k && counts[slot] != 0) ++slot;
        if (slot < k) { items[slot] = item; counts[slot] = 1; continue; }
        for (slot = 0; slot < k; ++slot) {
            --counts[slot];
            if (counts[slot] == 0) items[slot] = -1;
        }
    }
    size_t used = 0;
    for (size_t slot = 0; slot < k; ++slot) if (counts[slot] > 0) ++used;
    const size_t output_bytes = 8 * (1 + 2 * used);
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t ordered_items[MAX_K], ordered_counts[MAX_K];
    size_t at = 0;
    for (size_t slot = 0; slot < k; ++slot) {
        if (counts[slot] <= 0) continue;
        size_t position = at;
        while (position > 0 && ordered_items[position - 1] > items[slot]) {
            ordered_items[position] = ordered_items[position - 1];
            ordered_counts[position] = ordered_counts[position - 1];
            --position;
        }
        ordered_items[position] = items[slot];
        ordered_counts[position] = counts[slot];
        ++at;
    }
    store_i64_le(output, 0, (int64_t)used);
    for (size_t index = 0; index < used; ++index) {
        store_i64_le(output, 8 * (1 + 2 * index), ordered_items[index]);
        store_i64_le(output, 8 * (2 + 2 * index), ordered_counts[index]);
    }
    return (int64_t)output_bytes;
}

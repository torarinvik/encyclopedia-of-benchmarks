#include <stddef.h>
#include <stdint.h>

#define OP_LIMIT 128
#define ITEM_LIMIT 64
#define INPUT_LIMIT (1 + 3 * OP_LIMIT)
#define OUTPUT_LIMIT (3 + OP_LIMIT + ITEM_LIMIT)

static void store_i64(uint8_t *output, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t dynamicarray(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > INPUT_LIMIT || input[0] < 0 || input[0] > OP_LIMIT) return -1;
    int64_t a[ITEM_LIMIT] = {0}, b[ITEM_LIMIT] = {0}, queries[OP_LIMIT] = {0};
    size_t size = 0, capacity = 0, cursor = 1, query_count = 0, active = 0;
    for (int64_t opi = 0; opi < input[0]; ++opi) {
        if (cursor >= length) return -1;
        int64_t op = input[cursor++];
        if (op == 0) {
            if (cursor >= length || size >= ITEM_LIMIT) return -1;
            if (size == capacity) {
                if (active == 0) { for (size_t i = 0; i < size; ++i) b[i] = a[i]; active = 1; }
                else { for (size_t i = 0; i < size; ++i) a[i] = b[i]; active = 0; }
                capacity = capacity == 0 ? 10 : capacity * 2;
            }
            (active == 0 ? a : b)[size++] = input[cursor++];
        } else if (op == 1) {
            if (cursor + 1 >= length) return -1;
            int64_t index = input[cursor++], value = input[cursor++];
            if (index < 0 || (uint64_t)index >= size) return -1;
            (active == 0 ? a : b)[index] = value;
        } else if (op == 2 || op == 3) {
            if (cursor >= length) return -1;
            int64_t index = input[cursor++];
            if (index < 0 || (uint64_t)index >= size) return -1;
            int64_t *data = active == 0 ? a : b;
            if (op == 2) { if (query_count >= OP_LIMIT) return -1; queries[query_count++] = data[index]; }
            else { for (size_t i = (size_t)index; i + 1 < size; ++i) data[i] = data[i + 1]; --size; }
        } else if (op >= 4 && op <= 6) {
            if (query_count >= OP_LIMIT) return -1;
            queries[query_count++] = op == 4 ? (int64_t)size : op == 5 ? (int64_t)capacity : (size == 0 ? 1 : 0);
        } else return -1;
    }
    if (cursor != length) return -1;
    size_t words = 3 + query_count + size;
    if (output == NULL || output_capacity < words * 8) return -2;
    store_i64(output, 0, (int64_t)query_count);
    for (size_t i = 0; i < query_count; ++i) store_i64(output, i + 1, queries[i]);
    store_i64(output, query_count + 1, (int64_t)size);
    store_i64(output, query_count + 2, (int64_t)capacity);
    int64_t *data = active == 0 ? a : b;
    for (size_t i = 0; i < size; ++i) store_i64(output, query_count + 3 + i, data[i]);
    return (int64_t)words;
}

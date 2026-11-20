/* Clean-room bounded Bagwell two-dimensional VArray profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 321
#define MAX_Q 256
#define MAX_INPUT 580
#define DATA_SLOTS 352
#define POINTER_SLOTS 56
#define LEVEL_HEADERS 3

static const size_t value_start[3] = {0, 64, 320};
static const size_t side[3] = {8, 16, 32};
static const size_t pointer_start[3] = {0, 8, 24};
static const size_t data_start[3] = {0, 64, 320};

static void locate(size_t level, size_t index, size_t *pointer_slot, size_t *child_base,
                   size_t *element_offset) {
    size_t relative = index - value_start[level];
    size_t child = relative / side[level];
    *pointer_slot = pointer_start[level] + child;
    *child_base = data_start[level] + child * side[level];
    *element_offset = relative % side[level];
}

static int64_t find_level(size_t index, int64_t current_header,
                          const int64_t previous_header[LEVEL_HEADERS]) {
    int64_t level = current_header;
    while (level >= 0 && index < value_start[(size_t)level])
        level = previous_header[(size_t)level];
    return level;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t bagwell_varray_growth_index(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 0 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value;
    if ((n == 0 && q != 0) || length != 2 + n + q) return -1;
    size_t query_start = 2 + n;
    for (size_t j = 0; j < q; ++j)
        if (input[query_start + j] < 0 || (uint64_t)input[query_start + j] >= n) return -1;

    int64_t data[DATA_SLOTS] = {0};
    int64_t pointers[POINTER_SLOTS];
    int64_t previous_header[LEVEL_HEADERS] = {-1, -1, -1};
    size_t current_header = 0;
    for (size_t i = 0; i < POINTER_SLOTS; ++i) pointers[i] = -1;
    for (size_t i = 0; i < n; ++i) {
        if (i == 64 || i == 320) {
            size_t next_header = current_header + 1;
            previous_header[next_header] = (int64_t)current_header;
            current_header = next_header;
        }
        size_t slot, base, offset;
        locate(current_header, i, &slot, &base, &offset);
        if (pointers[slot] == -1) pointers[slot] = (int64_t)base;
        if (pointers[slot] != (int64_t)base || base + offset >= DATA_SLOTS) return -1;
        data[(size_t)pointers[slot] + offset] = input[2 + i];
    }

    size_t output_bytes = 8 * (q + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, q_value);
    for (size_t j = 0; j < q; ++j) {
        size_t index = (size_t)input[query_start + j];
        int64_t level = find_level(index, (int64_t)current_header, previous_header);
        size_t slot, base, offset;
        locate((size_t)level, index, &slot, &base, &offset);
        put_i64_le(output, 8 * (j + 1), data[(size_t)pointers[slot] + offset]);
    }
    return (int64_t)output_bytes;
}

/* Count three-array occurrences and emit keys with total count exactly three. */
#include <stddef.h>
#include <stdint.h>

#define ARRAY_COUNT 3
#define MAX_ARRAY_LENGTH 64
#define MAX_INPUT_LENGTH (ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1))
#define MAX_OCCURRENCES (ARRAY_COUNT * MAX_ARRAY_LENGTH)
#define TABLE_SIZE 257
#define BYTES_PER_VALUE 4

static void add_occurrence(int64_t value, int64_t *keys, size_t *counts,
                           uint8_t *occupied, size_t *order, size_t *order_length)
{
    int64_t remainder = value % TABLE_SIZE;
    if (remainder < 0) remainder += TABLE_SIZE;
    size_t slot = (size_t)remainder;
    while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % TABLE_SIZE;
    if (!occupied[slot]) {
        occupied[slot] = 1;
        keys[slot] = value;
        counts[slot] = 0;
        order[(*order_length)++] = slot;
    }
    ++counts[slot];
}

static void store_i32_le(uint8_t *output, size_t position, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t arrays_intersection(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < ARRAY_COUNT || length > MAX_INPUT_LENGTH) return -1;
    size_t starts[ARRAY_COUNT], sizes[ARRAY_COUNT];
    size_t position = 0;
    for (size_t array = 0; array < ARRAY_COUNT; ++array) {
        if (position >= length || input[position] < 0 || input[position] > MAX_ARRAY_LENGTH) return -1;
        const size_t size = (size_t)input[position++];
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (size_t index = 0; index < size; ++index)
            if (input[position + index] < INT32_MIN || input[position + index] > INT32_MAX) return -1;
        position += size;
    }
    if (position != length) return -1;

    int64_t keys[TABLE_SIZE];
    size_t counts[TABLE_SIZE] = {0};
    uint8_t occupied[TABLE_SIZE] = {0};
    size_t order[MAX_OCCURRENCES], order_length = 0;
    for (size_t array = 0; array < ARRAY_COUNT; ++array)
        for (size_t index = 0; index < sizes[array]; ++index)
            add_occurrence(input[starts[array] + index], keys, counts, occupied, order, &order_length);

    size_t match_count = 0;
    for (size_t index = 0; index < order_length; ++index)
        if (counts[order[index]] == ARRAY_COUNT) ++match_count;
    const size_t required = match_count * BYTES_PER_VALUE;
    if (output_capacity < required || (match_count > 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t index = 0; index < order_length; ++index) {
        const size_t slot = order[index];
        if (counts[slot] == ARRAY_COUNT) {
            store_i32_le(output, written * BYTES_PER_VALUE, keys[slot]);
            ++written;
        }
    }
    return (int64_t)written;
}

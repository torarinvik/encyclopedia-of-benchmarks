#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 99u
#define MAX_OPERATIONS 32u
#define MAX_CAPACITY 16u
#define MAX_OUTPUT_FIELDS 114u

static void append(int64_t *records, size_t *count, int64_t value)
{
    records[(*count)++] = value;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8u;
    }
}

int64_t lru(const int64_t *input, size_t length,
            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t capacity_value = input[0];
    const int64_t operation_count = input[1];
    if (capacity_value < 2 || capacity_value > (int64_t)MAX_CAPACITY
        || operation_count < 0 || operation_count > (int64_t)MAX_OPERATIONS
        || length != 2u + 3u * (size_t)operation_count) return -1;
    const size_t capacity = (size_t)capacity_value;

    int64_t keys[MAX_CAPACITY], values[MAX_CAPACITY], seen[MAX_OPERATIONS];
    size_t order[MAX_CAPACITY];
    int64_t records[MAX_OUTPUT_FIELDS];
    size_t cache_count = 0u, seen_count = 0u, record_count = 0u, cursor = 2u;
    for (int64_t step = 0; step < operation_count; ++step) {
        const int64_t opcode = input[cursor++];
        const int64_t key = input[cursor++];
        const int64_t value = input[cursor++];
        if (key < -1000000 || key > 1000000) return -1;

        if (opcode == 0) {
            if (value < -1000000 || value > 1000000) return -1;
            for (size_t index = 0; index < seen_count; ++index)
                if (seen[index] == key) return -1;
            seen[seen_count++] = key;

            size_t slot;
            if (cache_count == capacity) {
                slot = order[0];
                for (size_t index = 0; index + 1u < cache_count; ++index)
                    order[index] = order[index + 1u];
                --cache_count;
            } else {
                slot = cache_count;
            }
            keys[slot] = key;
            values[slot] = value;
            order[cache_count++] = slot;
            append(records, &record_count, 0);
            append(records, &record_count, 0);
        } else if (opcode == 1) {
            if (value != 0) return -1;
            size_t position = 0u;
            while (position < cache_count && keys[order[position]] != key) ++position;
            if (position == cache_count) return -1;
            const size_t slot = order[position];
            const int64_t cached_value = values[slot];
            for (size_t index = position; index + 1u < cache_count; ++index)
                order[index] = order[index + 1u];
            order[cache_count - 1u] = slot;
            append(records, &record_count, 1);
            append(records, &record_count, 1);
            append(records, &record_count, cached_value);
        } else {
            return -1;
        }
    }

    append(records, &record_count, 2);
    append(records, &record_count, (int64_t)cache_count);
    for (size_t index = 0; index < cache_count; ++index) {
        const size_t slot = order[index];
        append(records, &record_count, keys[slot]);
        append(records, &record_count, values[slot]);
    }

    const size_t output_bytes = record_count * 8u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < record_count; ++index)
        write_i64_le(output, index * 8u, records[index]);
    return (int64_t)output_bytes;
}

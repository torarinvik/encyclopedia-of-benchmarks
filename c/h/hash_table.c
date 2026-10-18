/* Collision-free integer-set membership for the shared hash-table contract. */
#include <stddef.h>
#include <stdint.h>

#define TABLE_CAPACITY 17
#define MAX_INSERT_COUNT 8
#define MAX_QUERY_COUNT 8
#define MAX_KEY 1000
#define MAX_PARSEABLE_LENGTH 19

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t hash_table(const int64_t *values, size_t length,
                   uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t raw_insert_count = values[0];
    if (raw_insert_count < 0 || raw_insert_count > MAX_INSERT_COUNT) return -1;
    const size_t insert_count = (size_t)raw_insert_count;
    const size_t query_count_index = 1 + insert_count;
    if (query_count_index >= length) return -1;
    const int64_t raw_query_count = values[query_count_index];
    if (raw_query_count < 1 || raw_query_count > MAX_QUERY_COUNT) return -1;
    const size_t query_count = (size_t)raw_query_count;
    const size_t query_start = query_count_index + 1;
    const size_t total_keys = insert_count + query_count;
    if (length != query_start + query_count) return -1;

    for (size_t index = 0; index < total_keys; ++index) {
        const size_t position = index < insert_count ? 1 + index : query_start + index - insert_count;
        const int64_t key = values[position];
        if (key < 1 || key > MAX_KEY) return -1;
        for (size_t prior = 0; prior < index; ++prior) {
            const size_t prior_position = prior < insert_count ? 1 + prior : query_start + prior - insert_count;
            const int64_t other = values[prior_position];
            const int same_group = (index < insert_count) == (prior < insert_count);
            if (key == other) {
                if (same_group) return -1;
            } else if (key % TABLE_CAPACITY == other % TABLE_CAPACITY || key % 3000 == other % 3000) {
                return -1;
            }
        }
    }

    int64_t table[TABLE_CAPACITY] = {0};
    for (size_t index = 0; index < insert_count; ++index) {
        const int64_t key = values[1 + index];
        table[(size_t)(key % TABLE_CAPACITY)] = key;
    }

    const size_t output_bytes = 8 * query_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < query_count; ++index) {
        const int64_t query = values[query_start + index];
        const int64_t found = table[(size_t)(query % TABLE_CAPACITY)] == query ? 1 : 0;
        store_i64_le(output, 8 * index, found);
    }
    return (int64_t)output_bytes;
}

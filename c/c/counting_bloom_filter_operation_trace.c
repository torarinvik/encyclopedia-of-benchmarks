#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_PARSEABLE_LENGTH 130
#define COUNTER_COUNT 67
#define HASH_COUNT 4

static void hash_positions(int64_t key, size_t positions[HASH_COUNT])
{
    const int64_t first = (17 * key + 3) % COUNTER_COUNT;
    const int64_t step = 1 + ((5 * key + 3) % (COUNTER_COUNT - 1));
    for (size_t index = 0; index < HASH_COUNT; ++index)
        positions[index] = (size_t)((first + (int64_t)index * step) % COUNTER_COUNT);
}

int64_t counting_bloom_filter_operation_trace(
    const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t q_value = input[0];
    if (q_value < 0 || q_value > MAX_OPERATIONS) return -1;
    const size_t q = (size_t)q_value;
    if (length != 1 + 2 * q) return -1;

    for (size_t operation_index = 0; operation_index < q; ++operation_index) {
        const int64_t opcode = input[1 + 2 * operation_index];
        const int64_t key = input[2 + 2 * operation_index];
        if (opcode < 0 || opcode > 2 || key < 0 || key > 65535) return -1;
    }

    if (output == NULL || output_capacity < q) return -2;

    uint8_t counters[COUNTER_COUNT] = {0};
    for (size_t operation_index = 0; operation_index < q; ++operation_index) {
        const int64_t opcode = input[1 + 2 * operation_index];
        const int64_t key = input[2 + 2 * operation_index];
        size_t positions[HASH_COUNT];
        hash_positions(key, positions);

        if (opcode == 0) {
            for (size_t hash = 0; hash < HASH_COUNT; ++hash)
                ++counters[positions[hash]];
            output[operation_index] = 1;
        } else if (opcode == 1) {
            /* The input contract guarantees that the deleted key is live. */
            for (size_t hash = 0; hash < HASH_COUNT; ++hash)
                --counters[positions[hash]];
            output[operation_index] = 1;
        } else {
            uint8_t present = 1;
            for (size_t hash = 0; hash < HASH_COUNT; ++hash)
                if (counters[positions[hash]] == 0) present = 0;
            output[operation_index] = present;
        }
    }
    return (int64_t)q;
}

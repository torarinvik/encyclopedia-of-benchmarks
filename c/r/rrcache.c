#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH (3 + 3 * MAX_OPERATIONS)
#define MAX_OUTPUT_BYTES (8 * MAX_OPERATIONS)

static uint32_t java_next_bits(uint64_t *state, unsigned bits) {
    const uint64_t mask = (UINT64_C(1) << 48) - 1;
    *state = (*state * UINT64_C(0x5DEECE66D) + UINT64_C(0xB)) & mask;
    return (uint32_t)(*state >> (48 - bits));
}

static uint32_t java_next_int(uint64_t *state, uint32_t bound) {
    if ((bound & (bound - 1)) == 0)
        return (uint32_t)(((uint64_t)bound * java_next_bits(state, 31)) >> 31);
    for (;;) {
        const uint32_t bits = java_next_bits(state, 31);
        const uint32_t value = bits % bound;
        if ((uint64_t)bits - value + (bound - 1) <= INT32_MAX) return value;
    }
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

int64_t rrcache(const int64_t *input, size_t length,
                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t capacity_value = input[0];
    const int64_t operation_count_value = input[2];
    if (capacity_value < 1 || capacity_value > 8 ||
        operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;

    const size_t cache_capacity = (size_t)capacity_value;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 3 + 3 * operation_count) return -1;

    int64_t keys[8] = {0};
    int64_t values[8] = {0};
    int64_t results[MAX_OPERATIONS] = {0};
    size_t size = 0;
    uint64_t random_state = ((uint64_t)input[1] ^ UINT64_C(0x5DEECE66D)) & ((UINT64_C(1) << 48) - 1);

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = 3 + 3 * operation;
        const int64_t opcode = input[offset];
        const int64_t key = input[offset + 1];
        const int64_t value = input[offset + 2];
        if (opcode == 0) {
            if (key < 1 || key > 1024 || value < 100 || value > 1000000) return -1;
            size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            if (index < size) {
                values[index] = value;
            } else {
                if (size == cache_capacity) {
                    const size_t evicted = java_next_int(&random_state, (uint32_t)size);
                    for (size_t move = evicted; move + 1 < size; ++move) {
                        keys[move] = keys[move + 1];
                        values[move] = values[move + 1];
                    }
                    --size;
                }
                keys[size] = key;
                values[size] = value;
                ++size;
            }
            results[operation] = -2;
        } else if (opcode == 1) {
            if (key < 1 || key > 1024 || value != 0) return -1;
            size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            results[operation] = index < size ? values[index] : -1;
        } else if (opcode == 2) {
            if (key != 0 || value != 0) return -1;
            results[operation] = (int64_t)size;
        } else {
            return -1;
        }
    }

    const size_t output_bytes = operation_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t operation = 0; operation < operation_count; ++operation)
        put_i64_le(staged, operation * 8, results[operation]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}

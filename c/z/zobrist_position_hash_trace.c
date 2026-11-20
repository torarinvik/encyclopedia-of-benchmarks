#include <stddef.h>
#include <stdint.h>

#define SLOTS 16
#define FEATURES 3
#define MAX_OPERATIONS 64
#define BASE_WORDS (1 + SLOTS * FEATURES + SLOTS)
#define MAX_VALID_WORDS (BASE_WORDS + 2 * MAX_OPERATIONS)

static void store_hash(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t zobrist_position_hash_trace(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < BASE_WORDS || length > MAX_VALID_WORDS + 1)
        return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS ||
        length != BASE_WORDS + 2 * (size_t)operation_count) return -1;

    for (size_t i = 0; i < SLOTS * FEATURES; ++i)
        if (input[1 + i] < 0) return -1;
    const size_t state_start = 1 + SLOTS * FEATURES;
    for (size_t slot = 0; slot < SLOTS; ++slot)
        if (input[state_start + slot] < 0 || input[state_start + slot] > FEATURES)
            return -1;
    const size_t edits_start = state_start + SLOTS;
    for (size_t edit = 0; edit < (size_t)operation_count; ++edit) {
        const int64_t slot = input[edits_start + 2 * edit];
        const int64_t feature = input[edits_start + 2 * edit + 1];
        if (slot < 0 || slot >= SLOTS || feature < 0 || feature > FEATURES)
            return -1;
    }

    const size_t required = 8 * ((size_t)operation_count + 1);
    if (output == NULL || capacity < required) return -2;

    uint8_t board[SLOTS];
    uint64_t hash = 0;
    for (size_t slot = 0; slot < SLOTS; ++slot) {
        const uint8_t feature = (uint8_t)input[state_start + slot];
        board[slot] = feature;
        if (feature != 0)
            hash ^= (uint64_t)input[1 + slot * FEATURES + feature - 1];
    }
    store_hash(output, 0, hash);

    for (size_t edit = 0; edit < (size_t)operation_count; ++edit) {
        const size_t slot = (size_t)input[edits_start + 2 * edit];
        const uint8_t next = (uint8_t)input[edits_start + 2 * edit + 1];
        const uint8_t previous = board[slot];
        if (previous != 0)
            hash ^= (uint64_t)input[1 + slot * FEATURES + previous - 1];
        if (next != 0)
            hash ^= (uint64_t)input[1 + slot * FEATURES + next - 1];
        board[slot] = next;
        store_hash(output, 8 * (edit + 1), hash);
    }
    return (int64_t)required;
}

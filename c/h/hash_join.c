#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, HASH_CAPACITY = 17, MAX_INPUT = 19, MAX_OUTPUT = 64 };

static size_t bucket_for(int64_t key)
{
    int64_t remainder = key % HASH_CAPACITY;
    if (remainder < 0) remainder += HASH_CAPACITY;
    return (size_t)remainder;
}

int64_t hash_join(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t left_value = input[0];
    const int64_t right_value = input[1];
    if (left_value < 0 || left_value > MAX_ROWS || right_value < 0 || right_value > MAX_ROWS) return -1;
    const size_t left_count = (size_t)left_value;
    const size_t right_count = (size_t)right_value;
    if (length != 2 + left_count + right_count) return -1;

    const int build_left = left_count < right_count;
    const size_t build_count = build_left ? left_count : right_count;
    const size_t probe_count = build_left ? right_count : left_count;
    const size_t build_offset = build_left ? 2 : 2 + left_count;
    const size_t probe_offset = build_left ? 2 + left_count : 2;
    int64_t keys[HASH_CAPACITY] = {0};
    int heads[HASH_CAPACITY];
    int tails[HASH_CAPACITY];
    int next_row[MAX_ROWS];
    uint8_t occupied[HASH_CAPACITY] = {0};
    uint8_t staged[MAX_OUTPUT] = {0};
    for (size_t slot = 0; slot < HASH_CAPACITY; ++slot) heads[slot] = tails[slot] = -1;
    for (size_t row = 0; row < MAX_ROWS; ++row) next_row[row] = -1;

    for (size_t row = 0; row < build_count; ++row) {
        const int64_t key = input[build_offset + row];
        size_t slot = bucket_for(key);
        while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
        if (!occupied[slot]) { occupied[slot] = 1; keys[slot] = key; }
        if (tails[slot] < 0) heads[slot] = (int)row;
        else next_row[tails[slot]] = (int)row;
        tails[slot] = (int)row;
    }

    size_t match_count = 0;
    for (size_t probe_row = 0; probe_row < probe_count; ++probe_row) {
        const int64_t key = input[probe_offset + probe_row];
        size_t slot = bucket_for(key);
        while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
        if (!occupied[slot]) continue;
        for (int build_row = heads[slot]; build_row >= 0; build_row = next_row[build_row]) {
            const size_t left_id = build_left ? (size_t)build_row : probe_row;
            const size_t right_id = build_left ? probe_row : (size_t)build_row;
            staged[match_count++] = (uint8_t)((left_id << 4) | right_id);
        }
    }
    if (output == NULL || capacity < match_count) return -2;
    for (size_t i = 0; i < match_count; ++i) output[i] = staged[i];
    return (int64_t)match_count;
}

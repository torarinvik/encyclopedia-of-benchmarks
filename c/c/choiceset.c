#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 1024
#define MAX_ELEMENTS 256
#define HASH_CAPACITY 512
#define MAX_KEY INT64_C(1000000000)

static size_t hash_slot(int32_t value)
{
    const uint64_t mixed = (uint64_t)(uint32_t)value * UINT64_C(2654435761);
    return (size_t)((uint32_t)mixed >> 23);
}

static size_t find_slot(const int32_t *keys, const int32_t *indices,
                        const uint8_t *states, int32_t value, bool *found)
{
    size_t slot = hash_slot(value), deleted = HASH_CAPACITY;
    for (size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (states[slot] == 0) {
            *found = false;
            return deleted < HASH_CAPACITY ? deleted : slot;
        }
        if (states[slot] == 2) {
            if (deleted == HASH_CAPACITY) deleted = slot;
        } else if (keys[slot] == value) {
            *found = true;
            return slot;
        }
        slot = (slot + 1) % HASH_CAPACITY;
    }
    *found = false;
    return deleted;
}

int64_t choiceset(const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)values[0];
    if (length != 1 + 2 * operation_count) return -1;
    const size_t output_bytes = operation_count * 8;

    int32_t elements[MAX_ELEMENTS] = {0}, map_keys[HASH_CAPACITY] = {0};
    int32_t map_indices[HASH_CAPACITY] = {0};
    uint8_t states[HASH_CAPACITY] = {0};
    int64_t results[MAX_OPERATIONS] = {0};
    size_t element_count = 0;

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const int64_t operation = values[1 + 2 * operation_index];
        const int64_t argument = values[2 + 2 * operation_index];
        if (operation >= 1 && operation <= 3) {
            if (argument < -MAX_KEY || argument > MAX_KEY) return -1;
            const int32_t key = (int32_t)argument;
            bool found = false;
            const size_t slot = find_slot(map_keys, map_indices, states, key, &found);
            if (operation == 1) {
                if (found) results[operation_index] = 0;
                else {
                    if (element_count == MAX_ELEMENTS || slot >= HASH_CAPACITY) return -1;
                    elements[element_count] = key;
                    map_keys[slot] = key;
                    map_indices[slot] = (int32_t)element_count;
                    states[slot] = 1;
                    ++element_count;
                    results[operation_index] = 1;
                }
            } else if (operation == 2) {
                results[operation_index] = found ? 1 : 0;
            } else if (!found) {
                results[operation_index] = 0;
            } else {
                const size_t index = (size_t)map_indices[slot];
                const size_t last = element_count - 1;
                if (index != last) {
                    const int32_t moved = elements[last];
                    bool moved_found = false;
                    const size_t moved_slot = find_slot(map_keys, map_indices, states, moved, &moved_found);
                    if (!moved_found) return -1;
                    elements[index] = moved;
                    map_indices[moved_slot] = (int32_t)index;
                }
                --element_count;
                states[slot] = 2;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (argument < 1 || (uint64_t)argument > element_count) return -1;
            results[operation_index] = elements[(size_t)argument - 1];
        } else return -1;
    }

    if (capacity < output_bytes || (output_bytes > 0 && output == NULL)) return -2;
    for (size_t index = 0; index < operation_count; ++index) {
        const uint64_t bits = (uint64_t)results[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}

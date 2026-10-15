#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 256
#define HASH_CAPACITY 512

static size_t hash_slot(int32_t value)
{
    const uint64_t mixed = (uint64_t)(uint32_t)value * UINT64_C(2654435761);
    return (size_t)((uint32_t)mixed >> 23);
}

static size_t find_slot(const int32_t *keys, const bool *occupied, int32_t value)
{
    size_t slot = hash_slot(value);
    for (size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot] || keys[slot] == value) return slot;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return 0;
}

static void put_i64_le(uint8_t *out, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t count_distinct_elements_in_window(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (input[1] < 1 || input[1] > (int64_t)n || length != n + 2) return -1;
    const size_t k = (size_t)input[1], out_n = n - k + 1;
    for (size_t i = 0; i < n; ++i) if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    if (output == NULL || capacity < out_n * 8) return -2;

    int32_t keys[HASH_CAPACITY] = {0}, counts[HASH_CAPACITY] = {0};
    bool occupied[HASH_CAPACITY] = {false};
    int64_t distinct = 0;
    for (size_t i = 0; i < k; ++i) {
        const int32_t value = (int32_t)input[i + 2];
        const size_t slot = find_slot(keys, occupied, value);
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot]++ == 0) ++distinct;
    }
    put_i64_le(output, 0, distinct);
    for (size_t i = k; i < n; ++i) {
        const int32_t incoming = (int32_t)input[i + 2];
        size_t slot = find_slot(keys, occupied, incoming);
        if (!occupied[slot]) { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot]++ == 0) ++distinct;

        const int32_t outgoing = (int32_t)input[i - k + 2];
        slot = find_slot(keys, occupied, outgoing);
        if (--counts[slot] == 0) --distinct;
        put_i64_le(output, (i - k + 1) * 8, distinct);
    }
    return (int64_t)(out_n * 8);
}

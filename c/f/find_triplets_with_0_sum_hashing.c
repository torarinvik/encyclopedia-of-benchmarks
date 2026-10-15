#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_TRIPLETS 2048
#define HASH_CAPACITY 128
#define BYTES_PER_TRIPLET 12

static size_t hash_slot(int64_t value)
{
    return (size_t)(((value + 100000) * 37) % HASH_CAPACITY);
}

static bool seen_contains(const int64_t *keys, const bool *occupied, int64_t value)
{
    size_t slot = hash_slot(value);
    for (size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot]) return false;
        if (keys[slot] == value) return true;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return false;
}

static void seen_add(int64_t *keys, bool *occupied, int64_t value)
{
    size_t slot = hash_slot(value);
    for (size_t probes = 0; probes < HASH_CAPACITY; ++probes) {
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; return; }
        if (keys[slot] == value) return;
        slot = (slot + 1) % HASH_CAPACITY;
    }
}

static void sort3(int64_t *a, int64_t *b, int64_t *c)
{
    int64_t t;
    if (*a > *b) { t = *a; *a = *b; *b = t; }
    if (*b > *c) { t = *b; *b = *c; *c = t; }
    if (*a > *b) { t = *a; *a = *b; *b = t; }
}

static bool already_output(const int64_t *triples, size_t count, int64_t a, int64_t b, int64_t c)
{
    for (size_t i = 0; i < count; ++i)
        if (triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c) return true;
    return false;
}

static void write_i32_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t find_triplets_with_0_sum_hashing(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (length > MAX_ITEMS || (length > 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (input[i] < -100000 || input[i] > 100000) return -1;

    int64_t triples[MAX_TRIPLETS * 3] = {0};
    size_t count = 0;
    for (size_t i = 0; i + 2 < length; ++i) {
        int64_t keys[HASH_CAPACITY] = {0};
        bool occupied[HASH_CAPACITY] = {false};
        for (size_t j = i + 1; j < length; ++j) {
            const int64_t other = input[j];
            const int64_t required = -input[i] - other;
            if (required >= -100000 && required <= 100000 && seen_contains(keys, occupied, required)) {
                int64_t a = input[i], b = other, c = required;
                sort3(&a, &b, &c);
                if (!already_output(triples, count, a, b, c) && count < MAX_TRIPLETS) {
                    triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c;
                    ++count;
                }
            }
            seen_add(keys, occupied, other);
        }
    }
    if (count == 0) return 0;
    const size_t needed = count * BYTES_PER_TRIPLET;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t i = 0; i < count * 3; ++i) write_i32_le(output, i * 4, triples[i]);
    return (int64_t)count;
}

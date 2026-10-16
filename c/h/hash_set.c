/* Bounded port of the pinned C hash set's ASCII-key insertion and lookup. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_IDS 64
#define MAX_INPUT_LENGTH 130
#define CAPACITY 1024
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t adler_key(int64_t id)
{
    uint64_t a = 1;
    uint64_t b = 0;
    const uint8_t prefix[] = {'k', 'e', 'y'};
    for (size_t i = 0; i < sizeof(prefix); ++i) {
        a = (a + prefix[i]) % UINT64_C(65521);
        b = (b + a) % UINT64_C(65521);
    }
    if (id >= 10) {
        a = (a + (uint64_t)(id / 10 + '0')) % UINT64_C(65521);
        b = (b + a) % UINT64_C(65521);
    }
    a = (a + (uint64_t)(id % 10 + '0')) % UINT64_C(65521);
    b = (b + a) % UINT64_C(65521);
    return (b << 16) | a;
}

static size_t bucket_for_id(int64_t id)
{
    const uint64_t hash = adler_key(id);
    return (size_t)((CAPACITY - 1) & (hash ^ (hash >> 12)));
}

static uint64_t fnv_word(uint64_t hash, int64_t word)
{
    const uint64_t bits = (uint64_t)word;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int64_t hash_set(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t add_count_value = input[0];
    if (add_count_value < 0 || add_count_value > MAX_IDS) return -1;
    const size_t add_count = (size_t)add_count_value;
    const size_t query_count_index = 1 + add_count;
    if (query_count_index >= length) return -1;
    const int64_t query_count_value = input[query_count_index];
    if (query_count_value < 0 || query_count_value > MAX_IDS) return -1;
    const size_t query_count = (size_t)query_count_value;
    if (length != 2 + add_count + query_count) return -1;

    for (size_t i = 0; i < add_count; ++i)
        if (input[1 + i] < 0 || input[1 + i] >= MAX_IDS) return -1;
    for (size_t i = 0; i < query_count; ++i)
        if (input[query_count_index + 1 + i] < 0 || input[query_count_index + 1 + i] >= MAX_IDS) return -1;

    bool occupied[CAPACITY] = {false};
    int64_t slot_ids[CAPACITY];
    int64_t set_length = 0;
    for (size_t i = 0; i < add_count; ++i) {
        const int64_t id = input[1 + i];
        const size_t bucket = bucket_for_id(id);
        if (!occupied[bucket]) {
            occupied[bucket] = true;
            slot_ids[bucket] = id;
            ++set_length;
        } else if (slot_ids[bucket] != id) {
            return -1;
        }
    }

    uint64_t result = fnv_word(FNV_OFFSET_BASIS, set_length);
    for (size_t i = 0; i < query_count; ++i) {
        const int64_t id = input[query_count_index + 1 + i];
        const size_t bucket = bucket_for_id(id);
        const int64_t contains = occupied[bucket] && slot_ids[bucket] == id ? 1 : 0;
        result = fnv_word(result, contains);
    }
    return (int64_t)(result & INT64_MAX);
}

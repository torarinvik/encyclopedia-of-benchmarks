#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 128u
#define MAX_CAPACITY 16u
#define MAX_INPUT_LENGTH (2u + 3u * MAX_OPERATIONS + 1u)
#define MAX_VALUE INT64_C(1000000)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ (uint64_t)byte) * FNV_PRIME;
}

static int64_t hash_responses(const int32_t *responses, size_t count)
{
    uint64_t hash = hash_byte(hash_byte(FNV_OFFSET, (uint8_t)count), (uint8_t)(count >> 8u));
    for (size_t index = 0; index < count; ++index) {
        const uint32_t bits = (uint32_t)responses[index];
        for (unsigned shift = 0; shift < 32u; shift += 8u)
            hash = hash_byte(hash, (uint8_t)(bits >> shift));
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}

int64_t mrucache(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t capacity64 = input[0];
    const int64_t operation_count64 = input[1];
    if (capacity64 < 1 || capacity64 > (int64_t)MAX_CAPACITY
        || operation_count64 < 0 || operation_count64 > (int64_t)MAX_OPERATIONS
        || length != 2u + 3u * (size_t)operation_count64) return -1;

    const size_t capacity = (size_t)capacity64;
    const size_t operation_count = (size_t)operation_count64;
    int32_t keys[MAX_CAPACITY];
    int32_t values[MAX_CAPACITY];
    int32_t responses[MAX_OPERATIONS];
    size_t cache_count = 0u;
    size_t response_count = 0u;

    for (size_t step = 0; step < operation_count; ++step) {
        const int64_t operation = input[2u + 3u * step];
        const int64_t key64 = input[3u + 3u * step];
        const int64_t value64 = input[4u + 3u * step];
        if (operation < 0 || operation > 1
            || key64 < INT32_MIN || key64 > INT32_MAX
            || value64 < INT32_MIN || value64 > INT32_MAX) return -1;

        const int32_t key = (int32_t)key64;
        const int32_t value = (int32_t)value64;
        size_t position = 0u;
        while (position < cache_count && keys[position] != key) ++position;

        if (operation == 0) {
            if (value < 0 || (int64_t)value > MAX_VALUE) return -1;
            if (position < cache_count) {
                for (size_t index = position; index + 1u < cache_count; ++index) {
                    keys[index] = keys[index + 1u];
                    values[index] = values[index + 1u];
                }
                keys[cache_count - 1u] = key;
                values[cache_count - 1u] = value;
            } else {
                if (cache_count == capacity) --cache_count; /* evict MRU tail */
                keys[cache_count] = key;
                values[cache_count] = value;
                ++cache_count;
            }
        } else if (position == cache_count) {
            responses[response_count++] = -1;
        } else {
            const int32_t response = values[position];
            for (size_t index = position; index + 1u < cache_count; ++index) {
                keys[index] = keys[index + 1u];
                values[index] = values[index + 1u];
            }
            keys[cache_count - 1u] = key;
            values[cache_count - 1u] = response;
            responses[response_count++] = response;
        }
    }

    return hash_responses(responses, response_count);
}

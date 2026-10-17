/* Bounded trace for the pinned Go separate-chaining hashmap. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 128
#define MAX_ENTRIES 128
#define MAX_INITIAL_CAPACITY 64
#define MAX_CAPACITY 256
#define MAX_INPUT_LENGTH (2 + 3 * MAX_OPERATIONS)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_byte(uint64_t hash, uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

static uint64_t hash_key(int64_t key) {
    uint64_t hash = FNV_OFFSET;
    uint64_t magnitude = (uint64_t)(key < 0 ? -key : key);
    uint8_t digits[10];
    size_t count = 0;
    do {
        digits[count++] = (uint8_t)(magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    if (key < 0) hash = hash_byte(hash, (uint8_t)'-');
    while (count != 0) hash = hash_byte(hash, (uint8_t)('0' + digits[--count]));
    return hash ^ (hash >> 16);
}

static size_t bucket_for(int64_t key, size_t capacity) {
    return (size_t)(hash_key(key) & (uint64_t)(capacity - 1));
}

static void put_i64_le(uint8_t *output, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t hashmap(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t initial_capacity = input[0];
    const int64_t operation_count = input[1];
    if (initial_capacity < 1 || initial_capacity > MAX_INITIAL_CAPACITY ||
        (initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
        operation_count > MAX_OPERATIONS || length != 2 + 3 * (size_t)operation_count) return -1;
    for (size_t i = 0; i < (size_t)operation_count; ++i) {
        const int64_t op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        if (op < 0 || op > 2 || key < INT32_MIN || key > INT32_MAX) return -1;
        if (op == 0) {
            if (value < INT32_MIN || value > INT32_MAX) return -1;
        } else if (value != 0) return -1;
    }

    int64_t keys[MAX_ENTRIES], values[MAX_ENTRIES], results[1 + 3 * MAX_OPERATIONS + 2];
    int next[MAX_ENTRIES], heads[MAX_CAPACITY], tails[MAX_CAPACITY];
    for (size_t i = 0; i < MAX_ENTRIES; ++i) next[i] = -1;
    for (size_t i = 0; i < MAX_CAPACITY; ++i) heads[i] = tails[i] = -1;
    size_t size = 0, map_capacity = (size_t)initial_capacity, result_words = 1, query_count = 0;

    for (size_t operation = 0; operation < (size_t)operation_count; ++operation) {
        const int64_t op = input[2 + 3 * operation], key = input[3 + 3 * operation];
        const int64_t value = input[4 + 3 * operation];
        const size_t bucket = bucket_for(key, map_capacity);
        int entry = heads[bucket];
        while (entry >= 0 && keys[entry] != key) entry = next[entry];
        if (op == 0) {
            if (entry >= 0) {
                values[entry] = value;
                continue;
            }
            if (size >= MAX_ENTRIES) return -1;
            entry = (int)size++;
            keys[entry] = key;
            values[entry] = value;
            if (heads[bucket] < 0) heads[bucket] = entry;
            else next[tails[bucket]] = entry;
            tails[bucket] = entry;
            if (size * 4 > map_capacity * 3) {
                int order[MAX_ENTRIES];
                size_t order_count = 0;
                for (size_t old_bucket = 0; old_bucket < map_capacity; ++old_bucket)
                    for (int node = heads[old_bucket]; node >= 0; node = next[node]) order[order_count++] = node;
                map_capacity *= 2;
                for (size_t i = 0; i < MAX_CAPACITY; ++i) heads[i] = tails[i] = -1;
                for (size_t i = 0; i < size; ++i) next[i] = -1;
                for (size_t i = 0; i < order_count; ++i) {
                    const int node = order[i];
                    const size_t new_bucket = bucket_for(keys[node], map_capacity);
                    if (heads[new_bucket] < 0) heads[new_bucket] = node;
                    else next[tails[new_bucket]] = node;
                    tails[new_bucket] = node;
                }
            }
        } else {
            results[result_words++] = op;
            if (op == 1) {
                results[result_words++] = entry >= 0 ? 1 : 0;
                results[result_words++] = entry >= 0 ? values[entry] : 0;
            } else results[result_words++] = entry >= 0 ? 1 : 0;
            ++query_count;
        }
    }
    results[0] = (int64_t)query_count;
    results[result_words++] = (int64_t)size;
    results[result_words++] = (int64_t)map_capacity;
    const size_t bytes = result_words * 8;
    if (output == NULL || output_capacity < bytes) return -2;
    for (size_t word = 0; word < result_words; ++word) put_i64_le(output, word, results[word]);
    return (int64_t)bytes;
}

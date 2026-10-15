/* Prefix preprocessing, inclusive range queries, and prefix-set membership. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define HASH_CAPACITY 1024

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static size_t hash_key(int64_t key) {
    int64_t bucket = key % HASH_CAPACITY;
    if (bucket < 0) bucket += HASH_CAPACITY;
    return (size_t)bucket;
}

static bool contains_subarray_sum(const int64_t *prefix, size_t length, int64_t target) {
    int64_t keys[HASH_CAPACITY] = {0};
    bool used[HASH_CAPACITY] = {false};
    size_t slot = hash_key(0);
    used[slot] = true; keys[slot] = 0;
    for (size_t end = 1; end <= length; ++end) {
        int64_t wanted = prefix[end] - target;
        slot = hash_key(wanted);
        while (used[slot] && keys[slot] != wanted) slot = (slot + 1) % HASH_CAPACITY;
        if (used[slot]) return true;
        slot = hash_key(prefix[end]);
        while (used[slot] && keys[slot] != prefix[end]) slot = (slot + 1) % HASH_CAPACITY;
        if (!used[slot]) { used[slot] = true; keys[slot] = prefix[end]; }
    }
    return false;
}

int64_t prefix_sum(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > 2 || input[1] < 0 || input[1] > MAX_LENGTH) return -1;
    const int64_t operation = input[0]; const size_t count = (size_t)input[1];
    const size_t expected_length = 2 + count + (operation == 1 ? 2 : operation == 2 ? 1 : 0);
    if (length != expected_length || (operation == 1 && count == 0)) return -1;
    for (size_t i = 0; i < count; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    if (operation == 1) {
        int64_t left = input[2 + count], right = input[3 + count];
        if (left < 0 || right < left || (uint64_t)right >= count) return -1;
    } else if (operation == 2 && (input[2 + count] < -INT64_C(1000000000000) || input[2 + count] > INT64_C(1000000000000))) return -1;
    int64_t prefix[MAX_LENGTH + 1] = {0};
    for (size_t i = 0; i < count; ++i) prefix[i + 1] = prefix[i] + input[2 + i];
    const size_t words = operation == 0 ? count : 1;
    if (output_capacity < words * 8 || (words != 0 && output == NULL)) return -2;
    if (operation == 0) {
        for (size_t i = 0; i < count; ++i) store_i64_le(output, i * 8, prefix[i + 1]);
        return (int64_t)count;
    }
    int64_t result;
    if (operation == 1) result = prefix[(size_t)input[3 + count] + 1] - prefix[(size_t)input[2 + count]];
    else result = contains_subarray_sum(prefix, count, input[2 + count]) ? 1 : 0;
    store_i64_le(output, 0, result);
    return 1;
}

#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 64
#define HASH_BASE INT64_C(257)
#define HASH_MODULUS INT64_C(1000000007)
#define HASH_SLOTS 64

int64_t distinct_substring_count_hashing(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_TEXT + 2) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_TEXT || length != (size_t)(n_value + 1)) return -1;
    const size_t n = (size_t)n_value;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    int64_t prefix[MAX_TEXT + 1] = {0};
    int64_t powers[MAX_TEXT + 1] = {0};
    powers[0] = 1;
    for (size_t i = 0; i < n; ++i) {
        prefix[i + 1] = (prefix[i] * HASH_BASE + input[i + 1] + 1) % HASH_MODULUS;
        powers[i + 1] = powers[i] * HASH_BASE % HASH_MODULUS;
    }

    int64_t group_hash[HASH_SLOTS];
    int64_t group_head[HASH_SLOTS];
    int64_t representative_start[MAX_TEXT];
    int64_t representative_next[MAX_TEXT];
    int64_t distinct = 0;
    for (size_t width = 1; width <= n; ++width) {
        for (size_t slot = 0; slot < HASH_SLOTS; ++slot) {
            group_hash[slot] = -1;
            group_head[slot] = -1;
        }
        size_t representative_count = 0;
        for (size_t start = 0; start + width <= n; ++start) {
            const size_t end = start + width;
            int64_t fingerprint = (prefix[end] - prefix[start] * powers[width] % HASH_MODULUS) % HASH_MODULUS;
            if (fingerprint < 0) fingerprint += HASH_MODULUS;
            size_t slot = (size_t)(fingerprint % HASH_SLOTS);
            while (group_hash[slot] != -1 && group_hash[slot] != fingerprint)
                slot = (slot + 1) % HASH_SLOTS;
            if (group_hash[slot] == -1) group_hash[slot] = fingerprint;

            int duplicate = 0;
            int64_t prior = group_head[slot];
            while (prior >= 0) {
                size_t offset = 0;
                const size_t prior_start = (size_t)representative_start[(size_t)prior];
                while (offset < width && input[start + offset + 1] == input[prior_start + offset + 1]) ++offset;
                if (offset == width) { duplicate = 1; break; }
                prior = representative_next[(size_t)prior];
            }
            if (!duplicate) {
                representative_start[representative_count] = (int64_t)start;
                representative_next[representative_count] = group_head[slot];
                group_head[slot] = (int64_t)representative_count++;
                ++distinct;
            }
        }
    }
    return distinct;
}

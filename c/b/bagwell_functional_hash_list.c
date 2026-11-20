/* Clean-room bounded Bagwell functional hash-list. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 131
#define MAX_OUTPUT 256
#define ENTRIES 56
#define BLOCKS 3

static const int starts[BLOCKS] = {0, 8, 24};
static const int sides[BLOCKS] = {8, 16, 32};

static void put_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t bagwell_functional_hash_list(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t nv = input[0];
    if (nv < 0 || nv > 32) return -1;
    size_t n = (size_t)nv, q_at = 1 + 2 * n;
    if (q_at >= length) return -1;
    int64_t qv = input[q_at];
    if (qv < 1 || qv > 32) return -1;
    size_t q = (size_t)qv, query_at = q_at + 1;
    if (length != 2 + 2 * n + 2 * q) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[1 + 2 * i] < INT32_MIN || input[1 + 2 * i] > INT32_MAX
            || input[2 + 2 * i] < INT32_MIN || input[2 + 2 * i] > INT32_MAX) return -1;
    for (size_t j = 0; j < q; ++j) {
        int64_t root = input[query_at + 2 * j], key = input[query_at + 2 * j + 1];
        if (root < 0 || root > nv || key < INT32_MIN || key > INT32_MAX) return -1;
    }
    size_t bytes = 8 * q;
    if (output == NULL || capacity < bytes) return -2;

    int64_t keys[ENTRIES] = {0}, values[ENTRIES] = {0};
    int next[ENTRIES], heads[ENTRIES], prev[BLOCKS], root_block[33], root_offset[33];
    for (int i = 0; i < ENTRIES; ++i) { next[i] = -1; heads[i] = -1; }
    for (int i = 0; i < BLOCKS; ++i) prev[i] = -1;
    for (int i = 0; i <= 32; ++i) { root_block[i] = -1; root_offset[i] = -1; }
    int current = 0;
    for (int i = 0; i < (int)n; ++i) {
        if (i == 8 || i == 24) { prev[current + 1] = current; ++current; }
        int offset = i - starts[current], slot = starts[current] + offset;
        uint32_t hash = (uint32_t)input[1 + 2 * (size_t)i];
        int bucket = (int)(hash & (uint32_t)(sides[current] - 1));
        int head_slot = starts[current] + bucket;
        keys[slot] = input[1 + 2 * (size_t)i];
        values[slot] = input[2 + 2 * (size_t)i];
        next[slot] = heads[head_slot];
        heads[head_slot] = offset;
        root_block[i + 1] = current;
        root_offset[i + 1] = offset;
    }

    for (size_t j = 0; j < q; ++j) {
        int64_t root = input[query_at + 2 * j], key = input[query_at + 2 * j + 1];
        int block = root_block[root], limit = root_offset[root];
        int64_t answer = INT64_MIN;
        if (block >= 0) {
            uint32_t hash = (uint32_t)key;
            int first = 1;
            while (block >= 0 && answer == INT64_MIN) {
                int bucket = (int)(hash & (uint32_t)(sides[block] - 1));
                int chain = heads[starts[block] + bucket];
                while (chain >= 0) {
                    if ((!first || chain <= limit) && keys[starts[block] + chain] == key) {
                        answer = values[starts[block] + chain];
                        break;
                    }
                    chain = next[starts[block] + chain];
                }
                block = prev[block];
                first = 0;
            }
        }
        put_i64_le(output, 8 * j, answer);
    }
    return (int64_t)bytes;
}

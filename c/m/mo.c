#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_VALUE 255
#define MAX_INPUT_WORDS (2 + MAX_N + 2 * MAX_Q)
#define MAX_PARSEABLE_INPUT_WORDS (MAX_INPUT_WORDS + 1)
#define MAX_OUTPUT_BYTES (4 * MAX_Q)

typedef struct { int32_t left, right, index; } Query;

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int ceil_sqrt(int n) {
    int block = 1;
    while (block * block < n) ++block;
    return block;
}

static bool query_before(Query a, Query b, int block_size) {
    const int a_block = a.left / block_size;
    const int b_block = b.left / block_size;
    if (a_block != b_block) return a_block < b_block;
    return a.right < b.right;
}

int64_t mo(const int32_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const int32_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const int n = (int)n_raw;
    const size_t q_offset = 1 + (size_t)n;
    if (length <= q_offset) return -1;
    const int32_t q_raw = input[q_offset];
    if (q_raw < 0 || q_raw > MAX_Q || length != q_offset + 1 + 2 * (size_t)q_raw) return -1;
    const int q_count = (int)q_raw;
    for (int i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > MAX_VALUE) return -1;

    Query queries[MAX_Q];
    for (int i = 0; i < q_count; ++i) {
        const int32_t left = input[q_offset + 1 + 2 * (size_t)i];
        const int32_t right = input[q_offset + 2 + 2 * (size_t)i];
        if (left < 1 || right < left || right > n) return -1;
        queries[i] = (Query){left - 1, right - 1, i};
    }
    const size_t bytes = 4 * (size_t)q_count;
    if (output == NULL || capacity < bytes) return -2;

    const int block_size = ceil_sqrt(n);
    for (int i = 1; i < q_count; ++i) {
        const Query value = queries[i];
        int j = i;
        while (j > 0 && query_before(value, queries[j - 1], block_size)) {
            queries[j] = queries[j - 1];
            --j;
        }
        queries[j] = value;
    }

    int32_t frequencies[MAX_VALUE + 1] = {0};
    int32_t answers[MAX_Q] = {0};
    int distinct = 0;
    int left = 0, right = 0;
    for (int i = 0; i < q_count; ++i) {
        const int target_left = queries[i].left;
        const int target_right = queries[i].right;
        while (left < target_left) {
            const int value = input[1 + left++];
            if (--frequencies[value] == 0) --distinct;
        }
        while (left > target_left) {
            const int value = input[1 + --left];
            if (++frequencies[value] == 1) ++distinct;
        }
        while (right <= target_right) {
            const int value = input[1 + right++];
            if (++frequencies[value] == 1) ++distinct;
        }
        while (right > target_right + 1) {
            const int value = input[1 + --right];
            if (--frequencies[value] == 0) --distinct;
        }
        answers[queries[i].index] = distinct;
    }

    for (int i = 0; i < q_count; ++i) put_i32_le(output, 4 * (size_t)i, answers[i]);
    return (int64_t)bytes;
}

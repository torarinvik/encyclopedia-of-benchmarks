#include <stddef.h>
#include <stdint.h>

#define MAX_M 32
#define MAX_N 32
#define MAX_Q 64
#define STRIDE (MAX_N + 1)
#define MAX_INPUT (3 + MAX_M + MAX_N + 3 * MAX_Q)

typedef struct { size_t a, b, c; } Query;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void fenwick_add(int *tree, size_t position, size_t count) {
    for (size_t index = position + 1; index <= count; index += index & (~index + 1))
        ++tree[index];
}

static int fenwick_prefix(const int *tree, size_t exclusive) {
    int total = 0;
    for (size_t index = exclusive; index > 0; index -= index & (~index + 1))
        total += tree[index];
    return total;
}

int64_t prefix_substring_lcs(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_M || input[1] < 1 || input[1] > MAX_N ||
        input[2] < 1 || input[2] > MAX_Q) return -1;
    const size_t m = (size_t)input[0], n = (size_t)input[1], q = (size_t)input[2];
    if (length != 3 + m + n + 3 * q) return -1;

    int s[MAX_M], t[MAX_N];
    size_t offset = 3;
    for (size_t i = 0; i < m; ++i) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        s[i] = (int)input[offset++];
    }
    for (size_t j = 0; j < n; ++j) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        t[j] = (int)input[offset++];
    }
    Query queries[MAX_Q];
    int query_head[STRIDE * STRIDE];
    int query_next[MAX_Q];
    for (size_t index = 0; index < STRIDE * STRIDE; ++index) query_head[index] = -1;
    for (size_t index = 0; index < q; ++index) {
        const int64_t a = input[offset++], b = input[offset++], c = input[offset++];
        if (a < 0 || a > (int64_t)m || b < 0 || b > c || c > (int64_t)n) return -1;
        queries[index] = (Query){(size_t)a, (size_t)b, (size_t)c};
        const size_t key = (size_t)a * STRIDE + (size_t)b;
        query_next[index] = query_head[key];
        query_head[key] = (int)index;
    }
    const size_t output_bytes = 8 * q;
    if (output == NULL || capacity < output_bytes) return -2;

    int horizontal[STRIDE][STRIDE] = {{0}};
    int vertical[STRIDE][STRIDE] = {{0}};
    for (size_t j = 0; j <= n; ++j) horizontal[0][j] = (int)j;
    for (size_t i = 1; i <= m; ++i) {
        for (size_t j = 1; j <= n; ++j) {
            const int above = horizontal[i - 1][j];
            const int left = vertical[i][j - 1];
            if (s[i - 1] == t[j - 1]) {
                horizontal[i][j] = left;
                vertical[i][j] = above;
            } else {
                horizontal[i][j] = above > left ? above : left;
                vertical[i][j] = above < left ? above : left;
            }
        }
    }

    int answers[MAX_Q] = {0};
    for (size_t a = 0; a <= m; ++a) {
        int value_head[STRIDE], value_next[STRIDE];
        for (size_t value = 0; value <= n; ++value) value_head[value] = -1;
        for (size_t position = 0; position <= n; ++position) {
            const size_t value = (size_t)horizontal[a][position];
            value_next[position] = value_head[value];
            value_head[value] = (int)position;
        }
        int fenwick[STRIDE + 1] = {0};
        for (size_t b = 0; b <= n; ++b) {
            for (int position = value_head[b]; position >= 0; position = value_next[position])
                fenwick_add(fenwick, (size_t)position, n + 1);
            for (int qi = query_head[a * STRIDE + b]; qi >= 0; qi = query_next[qi]) {
                const Query query = queries[qi];
                answers[qi] = fenwick_prefix(fenwick, query.c + 1) - fenwick_prefix(fenwick, query.b + 1);
            }
        }
    }
    for (size_t index = 0; index < q; ++index)
        store_i64_le(output, 8 * index, (int64_t)answers[index]);
    return (int64_t)output_bytes;
}

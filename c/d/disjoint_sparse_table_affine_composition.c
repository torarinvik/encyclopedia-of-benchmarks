/* Static ordered affine folds with a disjoint sparse table. */
#include <stddef.h>
#include <stdint.h>

#define DST_MOD INT64_C(1000000007)
#define DST_MAX_N 32
#define DST_MAX_Q 32
#define DST_MAX_LEVELS 5
#define DST_MAX_INPUT (2 + 2 * DST_MAX_N + 2 * DST_MAX_Q)

typedef struct { int64_t a; int64_t b; } dst_affine;

static dst_affine dst_combine(dst_affine left, dst_affine right)
{
    dst_affine result;
    result.a = (right.a * left.a) % DST_MOD;
    result.b = (right.a * left.b + right.b) % DST_MOD;
    return result;
}

static void dst_put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t disjoint_sparse_table_affine_composition(const int64_t *input, size_t length,
                                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > DST_MAX_INPUT) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > DST_MAX_N || q_value < 1 || q_value > DST_MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 2 * n + 2 * q) return -1;

    dst_affine maps[DST_MAX_N];
    size_t left[DST_MAX_Q], right[DST_MAX_Q];
    size_t cursor = 2;
    for (size_t i = 0; i < n; ++i) {
        const int64_t a = input[cursor++], b = input[cursor++];
        if (a < 0 || a >= DST_MOD || b < 0 || b >= DST_MOD) return -1;
        maps[i] = (dst_affine){a, b};
    }
    for (size_t i = 0; i < q; ++i) {
        const int64_t lo = input[cursor++], hi = input[cursor++];
        if (lo < 0 || lo > hi || hi >= n_value) return -1;
        left[i] = (size_t)lo;
        right[i] = (size_t)hi;
    }

    const size_t bytes = q * 16;
    if (output == NULL || capacity < bytes) return -2;

    dst_affine table[DST_MAX_LEVELS][DST_MAX_N] = {{{0, 0}}};
    size_t levels = 0;
    for (size_t span = 1; span < n; span <<= 1) ++levels;
    for (size_t level = 0; level < levels; ++level) {
        const size_t half = (size_t)1 << level;
        const size_t width = half << 1;
        for (size_t start = 0; start < n; start += width) {
            size_t middle = start + half;
            size_t end = start + width;
            if (middle > n) middle = n;
            if (end > n) end = n;
            if (middle > start) {
                table[level][middle - 1] = maps[middle - 1];
                for (size_t i = middle - 1; i > start; --i)
                    table[level][i - 1] = dst_combine(maps[i - 1], table[level][i]);
            }
            if (middle < end) {
                table[level][middle] = maps[middle];
                for (size_t i = middle + 1; i < end; ++i)
                    table[level][i] = dst_combine(table[level][i - 1], maps[i]);
            }
        }
    }

    for (size_t query = 0; query < q; ++query) {
        dst_affine answer;
        if (left[query] == right[query]) {
            answer = maps[left[query]];
        } else {
            size_t difference = left[query] ^ right[query];
            size_t level = 0;
            while (difference > 1) { difference >>= 1; ++level; }
            answer = dst_combine(table[level][left[query]], table[level][right[query]]);
        }
        dst_put_i64(output, query * 16, answer.a);
        dst_put_i64(output, query * 16 + 8, answer.b);
    }
    return (int64_t)bytes;
}

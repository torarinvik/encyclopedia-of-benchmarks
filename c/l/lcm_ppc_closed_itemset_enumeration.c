#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 8
#define MAX_ROWS 16
#define MAX_RECORDS (1u << MAX_ITEMS)
#define MAX_WORDS (1u + 2u * MAX_RECORDS)
#define MAX_INPUT_LENGTH (3u + MAX_ROWS)

typedef struct {
    const int64_t *rows;
    size_t item_count;
    size_t row_count;
    int64_t minimum_support;
    int64_t words[MAX_WORDS];
    size_t record_count;
} Context;

static size_t support(const Context *ctx, int64_t mask) {
    size_t count = 0;
    for (size_t row = 0; row < ctx->row_count; ++row)
        if ((ctx->rows[row] & mask) == mask) ++count;
    return count;
}

static int64_t closure(const Context *ctx, int64_t mask) {
    int64_t common = (INT64_C(1) << ctx->item_count) - 1;
    for (size_t row = 0; row < ctx->row_count; ++row)
        if ((ctx->rows[row] & mask) == mask) common &= ctx->rows[row];
    return common;
}

static int64_t core_index(const Context *ctx, int64_t mask, size_t pattern_support) {
    for (size_t item = 0; item < ctx->item_count; ++item) {
        const int64_t prefix_mask = (INT64_C(1) << (item + 1)) - 1;
        if (support(ctx, mask & prefix_mask) == pattern_support) return (int64_t)item;
    }
    return (int64_t)ctx->item_count - 1;
}

static void enumerate(Context *ctx, int64_t mask, size_t pattern_support, int64_t core) {
    const size_t record = ctx->record_count++;
    ctx->words[1 + 2 * record] = mask;
    ctx->words[2 + 2 * record] = (int64_t)pattern_support;

    for (int64_t item = core + 1; item < (int64_t)ctx->item_count; ++item) {
        const int64_t bit = INT64_C(1) << item;
        if ((mask & bit) != 0) continue;
        const int64_t extended = mask | bit;
        const size_t child_support = support(ctx, extended);
        if ((int64_t)child_support < ctx->minimum_support) continue;
        const int64_t child = closure(ctx, extended);
        const int64_t lower_prefix = bit - 1;
        if ((mask & lower_prefix) != (child & lower_prefix)) continue;
        enumerate(ctx, child, child_support, core_index(ctx, child, child_support));
    }
}

static void put_i64_le(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t lcm_ppc_closed_itemset_enumeration(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t item_count0 = input[0], row_count0 = input[1], minimum = input[2];
    if (item_count0 < 1 || item_count0 > MAX_ITEMS || row_count0 < 1 || row_count0 > MAX_ROWS ||
        minimum < 1 || minimum > row_count0 || length != 3u + (size_t)row_count0) return -1;
    const size_t item_count = (size_t)item_count0, row_count = (size_t)row_count0;
    const int64_t limit = INT64_C(1) << item_count;
    int64_t rows[MAX_ROWS];
    for (size_t row = 0; row < row_count; ++row) {
        const int64_t mask = input[3 + row];
        if (mask < 0 || mask >= limit) return -1;
        rows[row] = mask;
    }

    Context ctx = {0};
    ctx.rows = rows;
    ctx.item_count = item_count;
    ctx.row_count = row_count;
    ctx.minimum_support = minimum;
    const int64_t root = closure(&ctx, 0);
    enumerate(&ctx, root, row_count, -1);
    ctx.words[0] = (int64_t)ctx.record_count;
    const size_t output_bytes = 8u * (1u + 2u * ctx.record_count);
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < 1u + 2u * ctx.record_count; ++word)
        put_i64_le(output, word, ctx.words[word]);
    return (int64_t)output_bytes;
}

#include <stddef.h>
#include <stdint.h>

typedef struct {
    int64_t minimum_support;
    int64_t words[511];
    size_t records;
} Context;

static void enumerate(Context *ctx, const int64_t *rows, size_t row_count,
                      size_t item_count, size_t start_item, int64_t prefix) {
    for (size_t item = start_item; item < item_count; ++item) {
        const int64_t bit = INT64_C(1) << item;
        int64_t projected[16];
        size_t projected_count = 0;
        for (size_t row = 0; row < row_count; ++row)
            if ((rows[row] & bit) != 0) projected[projected_count++] = rows[row];
        if ((int64_t)projected_count < ctx->minimum_support) continue;
        const int64_t mask = prefix | bit;
        const size_t at = 1 + 2 * ctx->records++;
        ctx->words[at] = mask;
        ctx->words[at + 1] = (int64_t)projected_count;
        enumerate(ctx, projected, projected_count, item_count, item + 1, mask);
    }
}

static void put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t frequent_itemset_backtrack(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 19) return -1;
    const int64_t item_count0 = input[0], row_count0 = input[1], minimum = input[2];
    if (item_count0 < 1 || item_count0 > 8 || row_count0 < 1 || row_count0 > 16 ||
        minimum < 1 || minimum > row_count0 || length != 3 + (size_t)row_count0) return -1;
    const size_t item_count = (size_t)item_count0, row_count = (size_t)row_count0;
    const int64_t limit = INT64_C(1) << item_count;
    int64_t rows[16];
    for (size_t i = 0; i < row_count; ++i) {
        const int64_t mask = input[3 + i];
        if (mask < 0 || mask >= limit) return -1;
        rows[i] = mask;
    }
    Context ctx = {.minimum_support = minimum, .records = 0};
    enumerate(&ctx, rows, row_count, item_count, 0, 0);
    ctx.words[0] = (int64_t)ctx.records;
    const size_t bytes = 8 * (1 + 2 * ctx.records);
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < 1 + 2 * ctx.records; ++i) put_i64(output, i, ctx.words[i]);
    return (int64_t)bytes;
}

#include <stddef.h>
#include <stdint.h>

typedef struct {
    int64_t minimum_support;
    int order[8];
    int item_count;
    int64_t result;
} Context;

static void grow(Context *ctx, const int64_t *masks, const int64_t *weights,
                 size_t length, int rank_limit) {
    for (int rank = rank_limit - 1; rank >= 0; --rank) {
        const int item = ctx->order[rank];
        const int64_t bit = INT64_C(1) << item;
        int64_t support = 0;
        for (size_t i = 0; i < length; ++i)
            if ((masks[i] & bit) != 0) support += weights[i];
        if (support < ctx->minimum_support) continue;
        ++ctx->result;

        int64_t ancestor_mask = 0;
        for (int earlier = 0; earlier < rank; ++earlier)
            ancestor_mask |= INT64_C(1) << ctx->order[earlier];
        int64_t conditional_masks[64], conditional_weights[64];
        size_t conditional_length = 0;
        for (size_t i = 0; i < length; ++i) {
            if ((masks[i] & bit) != 0) {
                conditional_masks[conditional_length] = masks[i] & ancestor_mask;
                conditional_weights[conditional_length] = weights[i];
                ++conditional_length;
            }
        }
        grow(ctx, conditional_masks, conditional_weights, conditional_length, rank);
    }
}

int64_t frequent_pattern_growth(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > 67) return -1;
    const int64_t transaction_count = values[0], item_count = values[1];
    const int64_t minimum_support = values[2];
    if (transaction_count < 1 || transaction_count > 64 || item_count < 1 || item_count > 8 ||
        minimum_support < 1 || minimum_support > transaction_count ||
        length != (size_t)(3 + transaction_count)) return -1;
    const int64_t mask_limit = INT64_C(1) << item_count;
    int64_t masks[64], weights[64];
    for (int64_t i = 0; i < transaction_count; ++i) {
        if (values[3 + i] < 0 || values[3 + i] >= mask_limit) return -1;
        masks[i] = values[3 + i];
        weights[i] = 1;
    }
    int support[8] = {0};
    for (int item = 0; item < item_count; ++item)
        for (int64_t i = 0; i < transaction_count; ++i)
            support[item] += (masks[i] & (INT64_C(1) << item)) != 0;
    Context ctx = {.minimum_support = minimum_support, .item_count = (int)item_count, .result = 0};
    for (int i = 0; i < item_count; ++i) ctx.order[i] = i;
    for (int i = 1; i < item_count; ++i) {
        const int value = ctx.order[i];
        int j = i;
        while (j > 0 && (support[ctx.order[j - 1]] < support[value] ||
               (support[ctx.order[j - 1]] == support[value] && ctx.order[j - 1] > value))) {
            ctx.order[j] = ctx.order[j - 1];
            --j;
        }
        ctx.order[j] = value;
    }
    grow(&ctx, masks, weights, (size_t)transaction_count, (int)item_count);
    return ctx.result;
}

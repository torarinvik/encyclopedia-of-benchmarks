#include <cstddef>
#include <cstdint>

namespace {
struct Context { int64_t min_support; int order[8]; int64_t result = 0; };
void grow(Context &ctx, const int64_t *masks, const int64_t *weights,
          size_t length, int rank_limit) {
    for (int rank = rank_limit - 1; rank >= 0; --rank) {
        const int item = ctx.order[rank];
        const int64_t bit = INT64_C(1) << item;
        int64_t support = 0;
        for (size_t i = 0; i < length; ++i) if (masks[i] & bit) support += weights[i];
        if (support < ctx.min_support) continue;
        ++ctx.result;
        int64_t ancestors = 0;
        for (int r = 0; r < rank; ++r) ancestors |= INT64_C(1) << ctx.order[r];
        int64_t next_masks[64], next_weights[64];
        size_t next_length = 0;
        for (size_t i = 0; i < length; ++i) if (masks[i] & bit) {
            next_masks[next_length] = masks[i] & ancestors;
            next_weights[next_length++] = weights[i];
        }
        grow(ctx, next_masks, next_weights, next_length, rank);
    }
}
}

extern "C" int64_t frequent_pattern_growth(const int64_t *values, size_t length) {
    if (!values || length < 3 || length > 67) return -1;
    const int64_t n = values[0], m = values[1], minimum = values[2];
    if (n < 1 || n > 64 || m < 1 || m > 8 || minimum < 1 || minimum > n || length != size_t(3+n)) return -1;
    const int64_t limit = INT64_C(1) << m;
    int64_t masks[64], weights[64]; int support[8] = {};
    for (int64_t i=0; i<n; ++i) {
        if (values[3+i] < 0 || values[3+i] >= limit) return -1;
        masks[i] = values[3+i]; weights[i] = 1;
        for (int item=0; item<m; ++item) support[item] += (masks[i] >> item) & 1;
    }
    Context ctx{minimum, {}, 0};
    for (int i=0; i<m; ++i) ctx.order[i]=i;
    for (int i=1; i<m; ++i) { int item=ctx.order[i], j=i; while(j>0 && (support[ctx.order[j-1]]<support[item] || (support[ctx.order[j-1]]==support[item] && ctx.order[j-1]>item))) {ctx.order[j]=ctx.order[j-1];--j;} ctx.order[j]=item; }
    grow(ctx,masks,weights,size_t(n),int(m)); return ctx.result;
}

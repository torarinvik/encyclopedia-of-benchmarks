module frequent_pattern_growth;

struct Context { long minimum; long[8] order; long result; }

fn void grow(Context* ctx, long* masks, long* weights, usz length, usz rank_limit) {
    for (usz rank = rank_limit; rank > 0; rank--) {
        usz r = rank - 1;
        long bit = (long)1 << ctx.order[r];
        long support = 0;
        for (usz i = 0; i < length; i++) if ((masks[i] & bit) != 0) support += weights[i];
        if (support < ctx.minimum) continue;
        ctx.result++;
        long ancestor = 0;
        for (usz j = 0; j < r; j++) ancestor |= (long)1 << ctx.order[j];
        long[64] next_masks; long[64] next_weights; usz next_length = 0;
        for (usz i = 0; i < length; i++) if ((masks[i] & bit) != 0) {
            next_masks[next_length] = masks[i] & ancestor;
            next_weights[next_length] = weights[i];
            next_length++;
        }
        grow(ctx, &next_masks[0], &next_weights[0], next_length, r);
    }
}

fn long frequent_pattern_growth(long* a, usz n) @export("frequent_pattern_growth")
{
    if (a == null || n < 3 || n > 67) return -1;
    long rows = a[0];
    long items = a[1];
    long minimum = a[2];
    if (rows < 1 || rows > 64 || items < 1 || items > 8 || minimum < 1 || minimum > rows || n != (usz)(3 + rows)) return -1;
    long limit = (long)1 << items;
    for (long i = 0; i < rows; i++) if (a[(usz)(3 + i)] < 0 || a[(usz)(3 + i)] >= limit) return -1;
    long[8] support; long[8] order;
    for (long item = 0; item < items; item++) {
        support[item] = 0; order[item] = item;
        for (long row = 0; row < rows; row++) if ((a[(usz)(3 + row)] & ((long)1 << item)) != 0) support[item]++;
    }
    for (long i = 1; i < items; i++) {
        long value = order[i]; long j = i;
        while (j > 0 && (support[order[j - 1]] < support[value] || (support[order[j - 1]] == support[value] && order[j - 1] > value))) { order[j] = order[j - 1]; j--; }
        order[j] = value;
    }
    Context ctx; ctx.minimum = minimum; ctx.result = 0;
    for (long i = 0; i < items; i++) ctx.order[i] = order[i];
    long[64] masks; long[64] weights;
    for (long i = 0; i < rows; i++) { masks[i] = a[(usz)(3 + i)]; weights[i] = 1; }
    grow(&ctx, &masks[0], &weights[0], (usz)rows, (usz)items);
    return ctx.result;
}

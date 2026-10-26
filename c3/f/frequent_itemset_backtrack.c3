module frequent_itemset_backtrack;

struct Context { long minimum; long[511] words; usz records; }

fn void enumerate(Context* ctx, long* rows, usz row_count, usz item_count, usz start_item, long prefix) {
    for (usz item = start_item; item < item_count; item++) {
        long bit = (long)1 << (long)item;
        long[16] projected;
        usz projected_count = 0;
        for (usz row = 0; row < row_count; row++) if ((rows[row] & bit) != 0) {
            projected[projected_count] = rows[row]; projected_count++;
        }
        if ((long)projected_count < ctx.minimum) continue;
        long mask = prefix | bit;
        usz at = 1 + 2 * ctx.records;
        ctx.words[at] = mask; ctx.words[at + 1] = (long)projected_count; ctx.records++;
        enumerate(ctx, &projected[0], projected_count, item_count, item + 1, mask);
    }
}

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (b * 8));
}

fn long frequent_itemset_backtrack(long* input, usz length, uint8* output, usz capacity) @export("frequent_itemset_backtrack") {
    if (input == null || length < 4 || length > 19) return -1;
    long item_count0 = input[0], row_count0 = input[1], minimum = input[2];
    if (item_count0 < 1 || item_count0 > 8 || row_count0 < 1 || row_count0 > 16 ||
        minimum < 1 || minimum > row_count0 || length != (usz)(3 + row_count0)) return -1;
    usz item_count = (usz)item_count0, row_count = (usz)row_count0;
    long limit = (long)1 << item_count0;
    long[16] rows;
    for (usz i = 0; i < row_count; i++) {
        long mask = input[3 + i];
        if (mask < 0 || mask >= limit) return -1;
        rows[i] = mask;
    }
    Context ctx; ctx.minimum = minimum; ctx.records = 0;
    enumerate(&ctx, &rows[0], row_count, item_count, 0, 0);
    ctx.words[0] = (long)ctx.records;
    usz word_count = 1 + 2 * ctx.records;
    usz bytes = 8 * word_count;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) put_i64(output, i, ctx.words[i]);
    return (long)bytes;
}

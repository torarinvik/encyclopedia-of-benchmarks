module lcm_ppc_closed_itemset_enumeration;

const usz MAX_ITEMS = 8;
const usz MAX_ROWS = 16;
const usz MAX_RECORDS = 1 << MAX_ITEMS;
const usz MAX_WORDS = 1 + 2 * MAX_RECORDS;

struct Context {
    long* rows;
    usz item_count;
    usz row_count;
    long minimum_support;
    long[MAX_WORDS] words;
    usz record_count;
}

fn usz support(Context* ctx, long mask) {
    usz count = 0;
    for (usz row = 0; row < ctx.row_count; row++)
        if ((ctx.rows[row] & mask) == mask) count++;
    return count;
}

fn long closure(Context* ctx, long mask) {
    long common = ((long)1 << ctx.item_count) - 1;
    for (usz row = 0; row < ctx.row_count; row++)
        if ((ctx.rows[row] & mask) == mask) common &= ctx.rows[row];
    return common;
}

fn long core_index(Context* ctx, long mask, usz pattern_support) {
    for (usz item = 0; item < ctx.item_count; item++) {
        long prefix_mask = ((long)1 << (item + 1)) - 1;
        if (support(ctx, mask & prefix_mask) == pattern_support) return (long)item;
    }
    return (long)ctx.item_count - 1;
}

fn void enumerate(Context* ctx, long mask, usz pattern_support, long core) {
    usz record = ctx.record_count;
    ctx.record_count++;
    ctx.words[1 + 2 * record] = mask;
    ctx.words[2 + 2 * record] = (long)pattern_support;
    for (long item = core + 1; item < (long)ctx.item_count; item++) {
        long bit = (long)1 << item;
        if ((mask & bit) != 0) continue;
        long extended = mask | bit;
        usz child_support = support(ctx, extended);
        if ((long)child_support < ctx.minimum_support) continue;
        long child = closure(ctx, extended);
        long lower_prefix = bit - 1;
        if ((mask & lower_prefix) != (child & lower_prefix)) continue;
        enumerate(ctx, child, child_support, core_index(ctx, child, child_support));
    }
}

fn void put_i64_le(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (uint8)(bits >> (8 * byte));
}

fn long lcm_ppc_closed_itemset_enumeration(long* input, usz length,
        uint8* output, usz capacity) @export("lcm_ppc_closed_itemset_enumeration") {
    if (input == null || length < 4 || length > 3 + MAX_ROWS) return -1;
    long items0 = input[0], rows0 = input[1], minimum = input[2];
    if (items0 < 1 || items0 > (long)MAX_ITEMS || rows0 < 1 || rows0 > (long)MAX_ROWS ||
        minimum < 1 || minimum > rows0 || length != (usz)(3 + rows0)) return -1;
    usz item_count = (usz)items0, row_count = (usz)rows0;
    long limit = (long)1 << item_count;
    long[MAX_ROWS] rows;
    for (usz row = 0; row < row_count; row++) {
        long mask = input[3 + row];
        if (mask < 0 || mask >= limit) return -1;
        rows[row] = mask;
    }

    Context ctx;
    ctx.rows = &rows[0];
    ctx.item_count = item_count;
    ctx.row_count = row_count;
    ctx.minimum_support = minimum;
    ctx.record_count = 0;
    long root = closure(&ctx, 0);
    enumerate(&ctx, root, row_count, -1);
    ctx.words[0] = (long)ctx.record_count;
    usz output_bytes = 8 * (1 + 2 * ctx.record_count);
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < 1 + 2 * ctx.record_count; word++) put_i64_le(output, word, ctx.words[word]);
    return (long)output_bytes;
}

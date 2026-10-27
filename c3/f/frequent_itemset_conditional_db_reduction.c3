module frequent_itemset_conditional_db_reduction;

const usz MAX_ROWS = 64;
const usz MAX_INPUT = 69;
const usz MAX_OUTPUT = 1032;

fn void put_u64(uint8* output, usz word, ulong value) {
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (uint8)(value >> (byte * 8));
}

fn long frequent_itemset_conditional_db_reduction(long* input, usz length, uint8* output, usz capacity)
    @export("frequent_itemset_conditional_db_reduction") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long n0 = input[0], rows0 = input[1], minimum = input[2], tail = input[3], prefix0 = input[4];
    if (n0 < 1 || n0 > 8 || rows0 < 1 || rows0 > 64 || minimum < 1 || minimum > rows0 || length != (usz)(5 + rows0)) return -1;
    if (tail < -1 || tail >= n0 || prefix0 < 0) return -1;
    usz n = (usz)n0, rows = (usz)rows0;
    ulong limit = (ulong)1 << n, prefix = (ulong)prefix0;
    if (prefix >= limit || (tail == -1 && prefix != 0) ||
        (tail >= 0 && (((prefix >> (usz)tail) & 1) == 0 || (prefix >> ((usz)tail + 1)) != 0))) return -1;
    ulong[64] selected;
    ulong[8] support;
    for (usz i = 0; i < 64; i++) selected[i] = 0;
    for (usz i = 0; i < 8; i++) support[i] = 0;
    usz selected_count = 0;
    for (usz row = 0; row < rows; row++) {
        long row0 = input[5 + row];
        if (row0 < 0 || (ulong)row0 >= limit) return -1;
        ulong mask = (ulong)row0;
        if ((mask & prefix) != prefix) continue;
        selected[selected_count++] = mask;
        for (usz item = (usz)(tail + 1); item < n; item++)
            if ((mask & ((ulong)1 << item)) != 0) support[item]++;
    }
    if (selected_count < (usz)minimum) return -1;
    ulong keep = tail >= 0 ? (ulong)1 << (usz)tail : 0;
    for (usz item = (usz)(tail + 1); item < n; item++)
        if (support[item] >= (ulong)minimum) keep |= (ulong)1 << item;
    ulong below = tail > 0 ? ((ulong)1 << (usz)tail) - 1 : 0;
    ulong[64] masks;
    ulong[64] counts;
    for (usz i = 0; i < 64; i++) { masks[i] = 0; counts[i] = 0; }
    usz distinct = 0;
    for (usz row = 0; row < selected_count; row++) {
        ulong reduced = selected[row] & ~below & keep;
        usz at = 0;
        while (at < distinct && masks[at] != reduced) at++;
        if (at == distinct) { masks[distinct] = reduced; distinct++; }
        counts[at]++;
    }
    for (usz i = 1; i < distinct; i++) {
        ulong mask = masks[i], count = counts[i]; usz j = i;
        while (j > 0 && masks[j - 1] > mask) { masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; j--; }
        masks[j] = mask; counts[j] = count;
    }
    usz word_count = 1 + 2 * distinct, bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    put_u64(output, 0, distinct);
    for (usz i = 0; i < distinct; i++) { put_u64(output, 1 + 2 * i, masks[i]); put_u64(output, 2 + 2 * i, counts[i]); }
    return (long)bytes;
}

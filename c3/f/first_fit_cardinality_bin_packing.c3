module first_fit_cardinality_bin_packing;

fn void put_i64(uint8* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at * 8 + b] = (uint8)(bits >> (b * 8));
}

fn long first_fit_cardinality_bin_packing(long* input, usz length, uint8* output, usz capacity) @export("first_fit_cardinality_bin_packing") {
    if (input == null || length < 4 || length > 35) return -1;
    long n0 = input[0], limit = input[1], cap = input[2];
    if (n0 < 1 || n0 > 32 || limit < 1 || limit > 32 || cap < 1 || cap > 10000 || length != (usz)(n0 + 3)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[3 + i] < 1 || input[3 + i] > cap) return -1;
    long[32] loads; long[32] used; long[32] owners;
    usz bins = 0;
    for (usz i = 0; i < n; i++) {
        long size = input[3 + i]; usz b = 0;
        while (b < bins && (used[b] >= limit || loads[b] > cap - size)) b++;
        if (b == bins) bins++;
        loads[b] += size; used[b]++; owners[i] = (long)b;
    }
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, (long)bins);
    for (usz i = 0; i < n; i++) put_i64(output, i + 1, owners[i]);
    return (long)bytes;
}

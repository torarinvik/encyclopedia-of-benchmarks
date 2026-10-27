module next_fit_decreasing_bin_packing;

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long next_fit_decreasing_bin_packing(long* input, usz length, uint8* output, usz capacity)
    @export("next_fit_decreasing_bin_packing") {
    if (input == null || length < 1 || length > 65) return -1;
    long n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != (usz)(1 + n0)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    usz[64] order;
    long[64] assignments;
    for (usz i = 0; i < n; i++) order[i] = i;
    // Stable descending insertion sort; equal sizes keep increasing input index.
    for (usz i = 1; i < n; i++) {
        usz item = order[i], j = i;
        while (j > 0 && input[order[j - 1] + 1] < input[item + 1]) { order[j] = order[j - 1]; j--; }
        order[j] = item;
    }
    long bins = 0, remaining = 0;
    for (usz rank = 0; rank < n; rank++) {
        usz item = order[rank];
        long size = input[item + 1];
        if (bins == 0 || size > remaining) { assignments[item] = bins; bins++; remaining = 1000000 - size; }
        else { assignments[item] = bins - 1; remaining -= size; }
    }
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, bins);
    for (usz i = 0; i < n; i++) put_i64(output, i + 1, assignments[i]);
    return (long)bytes;
}

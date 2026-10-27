module first_fit_decreasing_bin_packing;

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long first_fit_decreasing_bin_packing(long* input, usz length, uint8* output, usz capacity)
    @export("first_fit_decreasing_bin_packing") {
    if (input == null || length < 1 || length > 65) return -1;
    long n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != (usz)(1 + n0)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    usz[64] order; long[64] loads = {0}; long[64] assignments = {0};
    for (usz i = 0; i < n; i++) order[i] = i;
    for (usz i = 1; i < n; i++) {
        usz key = order[i], j = i;
        while (j > 0 && input[order[j - 1] + 1] < input[key + 1]) { order[j] = order[j - 1]; j--; }
        order[j] = key;
    }
    usz bins = 0;
    for (usz pos = 0; pos < n; pos++) {
        usz item = order[pos]; long size = input[item + 1];
        usz selected = 0;
        while (selected < bins && loads[selected] + size > 1000000) selected++;
        if (selected == bins) { loads[bins] = size; assignments[item] = (long)bins; bins++; }
        else { loads[selected] += size; assignments[item] = (long)selected; }
    }
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, (long)bins);
    for (usz i = 0; i < n; i++) put_i64(output, i + 1, assignments[i]);
    return (long)bytes;
}

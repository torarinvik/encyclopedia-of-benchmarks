module best_fit_bin_packing;

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long best_fit_bin_packing(long* input, usz length, uint8* output, usz capacity)
    @export("best_fit_bin_packing") {
    if (input == null || length < 1 || length > 65) return -1;
    long n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != (usz)(1 + n0)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    long[64] loads = {0}; long[64] assignments = {0};
    usz bins = 0;
    for (usz i = 0; i < n; i++) {
        long size = input[i + 1];
        usz selected = bins;
        long least_remaining = 1000001;
        for (usz bin = 0; bin < bins; bin++) {
            if (loads[bin] + size <= 1000000) {
                long remaining = 1000000 - loads[bin] - size;
                if (remaining < least_remaining) { least_remaining = remaining; selected = bin; }
            }
        }
        if (selected == bins) { loads[bins] = size; assignments[i] = (long)bins; bins++; }
        else { loads[selected] += size; assignments[i] = (long)selected; }
    }
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, (long)bins);
    for (usz i = 0; i < n; i++) put_i64(output, i + 1, assignments[i]);
    return (long)bytes;
}

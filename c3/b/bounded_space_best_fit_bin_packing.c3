module bounded_space_best_fit_bin_packing;

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long bounded_space_best_fit_bin_packing(long* input, usz length, uint8* output, usz output_capacity)
    @export("bounded_space_best_fit_bin_packing") {
    if (input == null || length < 1 || length > 65) return -1;
    long n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != (usz)(1 + n0)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    long[64] loads = {0}, assignments = {0};
    bool[64] open = {false};
    usz bins = 0;
    for (usz item = 0; item < n; item++) {
        long size = input[item + 1];
        usz selected = bins;
        long least_remaining = 1000001;
        for (usz bin = 0; bin < bins; bin++) if (open[bin] && loads[bin] + size <= 1000000) {
            long remaining = 1000000 - loads[bin] - size;
            if (remaining < least_remaining) { least_remaining = remaining; selected = bin; }
        }
        if (selected == bins) {
            loads[bins] = size; open[bins] = size < 1000000; assignments[item] = (long)bins; bins++;
        } else {
            loads[selected] += size; assignments[item] = (long)selected;
            if (loads[selected] == 1000000) open[selected] = false;
        }
        usz partial_open = 0;
        for (usz bin = 0; bin < bins; bin++) if (open[bin]) partial_open++;
        while (partial_open > 2) {
            usz weakest = bins;
            for (usz bin = 0; bin < bins; bin++) if (open[bin] && (weakest == bins || loads[bin] < loads[weakest] || (loads[bin] == loads[weakest] && bin > weakest))) weakest = bin;
            open[weakest] = false; partial_open--;
        }
    }
    usz bytes = 8 * (n + 1);
    if (output == null || output_capacity < bytes) return -2;
    put_i64(output, 0, (long)bins);
    for (usz item = 0; item < n; item++) put_i64(output, item + 1, assignments[item]);
    return (long)bytes;
}

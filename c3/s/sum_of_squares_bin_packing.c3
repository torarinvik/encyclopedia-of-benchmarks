module sum_of_squares_bin_packing;

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long sum_of_squares_bin_packing(long* input, usz length, uint8* output, usz output_capacity)
    @export("sum_of_squares_bin_packing") {
    if (input == null || length < 2 || length > 66) return -1;
    long capacity0 = input[0], n0 = input[1];
    if (capacity0 < 1 || capacity0 > 64 || n0 < 0 || n0 > 64 || length != (usz)(2 + n0)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[i + 2] < 1 || input[i + 2] > capacity0) return -1;
    long[65] histogram = {0}; long[64] loads = {0}; long[64] assignments = {0};
    usz bins = 0;
    long score = 0;
    for (usz item = 0; item < n; item++) {
        long size = input[item + 2];
        usz selected = bins;
        long best_score = 9223372036854775807;
        for (usz bin = 0; bin < bins; bin++) {
            long from = loads[bin], to = from + size;
            if (to > capacity0) continue;
            long candidate = score;
            if (from < capacity0) candidate += (histogram[from] - 1) * (histogram[from] - 1) - histogram[from] * histogram[from];
            if (to < capacity0) candidate += (histogram[to] + 1) * (histogram[to] + 1) - histogram[to] * histogram[to];
            if (candidate < best_score) { best_score = candidate; selected = bin; }
        }
        long new_score = score;
        if (size < capacity0) new_score += (histogram[size] + 1) * (histogram[size] + 1) - histogram[size] * histogram[size];
        if (new_score < best_score) { best_score = new_score; selected = bins; }
        if (selected == bins) {
            loads[bins] = size; assignments[item] = (long)bins;
            if (size < capacity0) histogram[size]++;
            bins++;
        } else {
            long from = loads[selected], to = from + size;
            if (from < capacity0) histogram[from]--;
            if (to < capacity0) histogram[to]++;
            loads[selected] = to; assignments[item] = (long)selected;
        }
        score = best_score;
    }
    usz bytes = 8 * (n + 1);
    if (output == null || output_capacity < bytes) return -2;
    put_i64(output, 0, (long)bins);
    for (usz item = 0; item < n; item++) put_i64(output, item + 1, assignments[item]);
    return (long)bytes;
}

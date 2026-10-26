module approximate_tandem_squares;

fn void put_i64(uint8* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at * 8 + b] = (uint8)(bits >> (b * 8));
}

fn long approximate_tandem_squares(long* input, usz length, uint8* output, usz capacity) @export("approximate_tandem_squares") {
    if (input == null || length < 2 || length > 34) return -1;
    long n0 = input[0], budget = input[1];
    if (n0 < 2 || n0 > 32 || budget < 0 || budget > 8 || length != (usz)(n0 + 2)) return -1;
    usz n = (usz)n0;
    for (usz i = 0; i < n; i++) if (input[2 + i] < 0 || input[2 + i] > 3) return -1;
    long[768] records;
    usz count = 0;
    for (usz start = 0; start < n; start++) {
        for (usz period = 1; 2 * period <= n - start; period++) {
            long mismatches = 0;
            for (usz i = 0; i < period; i++)
                if (input[2 + start + i] != input[2 + start + period + i]) mismatches++;
            if (mismatches <= budget) {
                records[3 * count] = (long)start;
                records[3 * count + 1] = (long)period;
                records[3 * count + 2] = mismatches;
                count++;
            }
        }
    }
    usz bytes = 8 * (1 + 3 * count);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, (long)count);
    for (usz i = 0; i < 3 * count; i++) put_i64(output, 1 + i, records[i]);
    return (long)bytes;
}

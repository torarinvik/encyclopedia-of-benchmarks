module approximate_tandem_k_runs;

const int MAX_TEXT = 24;
const int MAX_INPUT = 26;
const usz MAX_OUTPUT = 34504;

fn usz max_window_mismatches(long *text, usz start, usz length, usz period) {
    usz maximum = 0;
    usz windows = length - 2 * period + 1;
    for (usz window = 0; window < windows; window++) {
        usz count = 0;
        for (usz offset = 0; offset < period; offset++)
            if (text[start + window + offset] != text[start + window + period + offset]) count++;
        if (count > maximum) maximum = count;
    }
    return maximum;
}

fn usz count_records(long *text, usz n, usz budget) {
    usz count = 0;
    for (usz start = 0; start < n; start++) {
        usz remaining = n - start;
        for (usz period = 1; 2 * period + 1 <= remaining; period++)
            for (usz factor_length = 2 * period + 1; factor_length <= remaining; factor_length++)
                if (max_window_mismatches(text, start, factor_length, period) <= budget) count++;
    }
    return count;
}
fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long approximate_tandem_k_runs(long *input, usz length, uint8 *output, usz capacity)
    @export("approximate_tandem_k_runs") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n0 = input[0], budget0 = input[1];
    if (n0 < 3 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 8 || length != (usz)n0 + 2) return -1;
    usz n = (usz)n0, budget = (usz)budget0;
    long *text = input + 2;
    for (usz i = 0; i < n; i++) if (text[i] < 0 || text[i] > 3) return -1;
    usz count = count_records(text, n, budget);
    usz bytes = 8 * (1 + 4 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    store_i64_le(output, 0, (long)count);
    usz record = 0;
    for (usz start = 0; start < n; start++) {
        usz remaining = n - start;
        for (usz period = 1; 2 * period + 1 <= remaining; period++)
            for (usz factor_length = 2 * period + 1; factor_length <= remaining; factor_length++) {
                usz errors = max_window_mismatches(text, start, factor_length, period);
                if (errors <= budget) {
                    usz offset = 8 * (1 + 4 * record++);
                    store_i64_le(output, offset, (long)start);
                    store_i64_le(output, offset + 8, (long)factor_length);
                    store_i64_le(output, offset + 16, (long)period);
                    store_i64_le(output, offset + 24, (long)errors);
                }
            }
    }
    return (long)bytes;
}

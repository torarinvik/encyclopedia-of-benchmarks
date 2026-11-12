module burnside_bracelets;

const usz MAX_N = 10;
const usz MAX_INPUT_VALUES = 3;
const usz OUTPUT_BYTES = 8;

fn usz cycle_count(usz n, usz shift, bool reflection) {
    bool[MAX_N] seen = zeroed;
    usz cycles = 0;
    for (usz start = 0; start < n; start += 1) {
        if (seen[start]) continue;
        cycles += 1;
        usz position = start;
        while (!seen[position]) {
            seen[position] = true;
            if (reflection) position = (shift + n - position) % n;
            else position = (position + shift) % n;
        }
    }
    return cycles;
}

fn long fixed_colorings(usz n, usz shift, bool reflection, long colors) {
    usz cycles = cycle_count(n, shift, reflection);
    long result = 1;
    for (usz cycle = 0; cycle < cycles; cycle += 1) result *= colors;
    return result;
}

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < OUTPUT_BYTES; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long burnside_bracelets(long* input, usz length, char* output, usz capacity)
    @export("burnside_bracelets") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    if (length != 2) return -1;
    long n_value = input[0];
    long colors = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || colors < 0 || colors > 3) return -1;
    usz n = (usz)n_value;

    long fixed_sum = 0;
    for (usz shift = 0; shift < n; shift += 1) {
        fixed_sum += fixed_colorings(n, shift, false, colors);
        fixed_sum += fixed_colorings(n, shift, true, colors);
    }
    long answer = fixed_sum / (long)(2 * n);
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    store_i64_le(output, answer);
    return (long)OUTPUT_BYTES;
}

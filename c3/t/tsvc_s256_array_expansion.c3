// Clean-room bounded port of TSVC s256; see package README for provenance.
module tsvc_s256_array_expansion;

const usz MAX_N = 16;
const usz MAX_CELLS = MAX_N * MAX_N;
const usz MAX_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_CELLS;
const usz MAX_C0 = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

long tsvc_s256_array_expansion(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s256_array_expansion") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], a0 = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || a0 < -1000 || a0 > 1000) return -1;
    usz n = (usz)n_raw;
    usz cells = n * n;
    if (length != 2 + n + 2 * cells) return -1;
    usz d_start = 2, b_start = d_start + n, c_start = b_start + cells;
    for (usz i = 0; i < n; i++)
        if (input[d_start + i] < -1000 || input[d_start + i] > 1000) return -1;
    for (usz i = 0; i < cells; i++) {
        if (input[b_start + i] < -1000 || input[b_start + i] > 1000 ||
            input[c_start + i] < -(long)MAX_C0 || input[c_start + i] > (long)MAX_C0) return -1;
    }

    usz output_values = n + cells;
    if (output == null || output_capacity < output_values * 8) return -2;
    long[MAX_N] a;
    long[MAX_CELLS] c;
    for (usz i = 0; i < n; i++) a[i] = 0;
    a[0] = a0;
    for (usz cell = 0; cell < cells; cell++) c[cell] = input[c_start + cell];
    for (usz column = 0; column < n; column += 1) {
        for (usz row = 1; row < n; row += 1) {
            a[row] = 1 - a[row - 1];
            usz cell = row * n + column;
            c[cell] = a[row] + input[b_start + cell] * input[d_start + row];
        }
    }
    for (usz row = 0; row < n; row++) store_i64_le(output, row * 8, a[row]);
    for (usz cell = 0; cell < cells; cell++) store_i64_le(output, (n + cell) * 8, c[cell]);
    return (long)output_values;
}

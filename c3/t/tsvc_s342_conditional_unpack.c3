module tsvc_s342_conditional_unpack;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_N;
const long MAX_VALUE = 2;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s342_conditional_unpack(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s342_conditional_unpack") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 2 * n) return -1;

    usz a_start = 1, b_start = a_start + n;
    long[MAX_N] a;
    for (usz i = 0; i < n; i += 1) {
        a[i] = input[a_start + i];
        if (a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
            input[b_start + i] < -MAX_VALUE || input[b_start + i] > MAX_VALUE) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    usz packed_index = 0;
    for (usz i = 0; i < n; i += 1) {
        if (a[i] > 0) {
            a[i] = input[b_start + packed_index];
            packed_index += 1;
        }
    }
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}

module tsvc_s315_maximum_with_index;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + MAX_N;
const long MAX_VALUE = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s315_maximum_with_index(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s315_maximum_with_index") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + n) return -1;
    for (usz i = 0; i < n; i += 1)
        if (input[i + 1] < -MAX_VALUE || input[i + 1] > MAX_VALUE) return -1;
    if (output == null || output_capacity < 16) return -2;

    long maximum = input[1];
    usz maximum_index = 0;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value > maximum) {
            maximum = value;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, (long)maximum_index);
    return 2;
}

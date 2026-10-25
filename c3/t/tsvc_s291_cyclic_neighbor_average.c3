module tsvc_s291_cyclic_neighbor_average;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + MAX_N;
const long MAX_VALUE = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s291_cyclic_neighbor_average_impl(long* input, usz length,
        char* output, usz output_capacity) {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 2 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + n) return -1;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    for (usz i = 0; i < n; i += 1) {
        usz previous = i == 0 ? n - 1 : i - 1;
        store_i64_le(output, 8 * i, input[i + 1] + input[previous + 1]);
    }
    return (long)n;
}

fn long tsvc_s291_cyclic_neighbor_average(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s291_cyclic_neighbor_average") {
    return tsvc_s291_cyclic_neighbor_average_impl(input, length, output, output_capacity);
}

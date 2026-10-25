module tsvc_s318_strided_absolute_maximum_with_index;

const usz MAX_N = 64;
const usz MAX_STRIDE = 4;
const usz MAX_PHYSICAL_N = 1 + (MAX_N - 1) * MAX_STRIDE;
const usz MAX_INPUT_LENGTH = 2 + MAX_PHYSICAL_N;
const long MAX_VALUE = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s318_strided_absolute_maximum_with_index_impl(long* input, usz length,
        char* output, usz output_capacity) {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    long stride_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || stride_raw < 1 || stride_raw > (long)MAX_STRIDE) return -1;
    usz n = (usz)n_raw;
    usz stride = (usz)stride_raw;
    usz physical_n = 1 + (n - 1) * stride;
    if (length != 2 + physical_n) return -1;
    for (usz i = 0; i < physical_n; i += 1) {
        long value = input[i + 2];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
    }
    if (output == null || output_capacity < 16) return -2;

    long first = input[2];
    long maximum = first < 0 ? -first : first;
    usz maximum_index = 0;
    for (usz i = 1; i < n; i += 1) {
        long value = input[2 + i * stride];
        long magnitude = value < 0 ? -value : value;
        if (magnitude > maximum) {
            maximum = magnitude;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, (long)maximum_index);
    return 2;
}

fn long tsvc_s318_strided_absolute_maximum_with_index(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s318_strided_absolute_maximum_with_index") {
    return tsvc_s318_strided_absolute_maximum_with_index_impl(input, length, output, output_capacity);
}

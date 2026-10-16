module get_products_of_all_other_elements;

const usz MAX_ARRAY_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 34;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long get_products_of_all_other_elements(long* input, usz length, char* output, usz capacity) @export("get_products_of_all_other_elements") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    long[MAX_ARRAY_LENGTH] result;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < -2 || input[i + 1] > 2) return -1;
    }
    if (n < 2) return 0;
    usz output_bytes = n * 8;
    if (output == null || capacity < output_bytes) return -2;

    result[0] = 1;
    for (usz i = 0; i < n - 1; i++) result[i + 1] = input[i + 1] * result[i];
    long suffix = 1;
    for (usz i = n - 1; i > 0; i--) {
        long value = input[i + 1];
        result[i - 1] *= suffix * value;
        suffix *= value;
    }
    for (usz i = 0; i < n; i++) write_i64_le(output, i * 8, result[i]);
    return (long)output_bytes;
}

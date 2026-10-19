module stream_vector_kernels;

const usz MAX_COUNT = 128;
const usz MAX_INPUT_LENGTH = 259;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long stream_vector_kernels(long* input, usz length, char* output, usz capacity)
    @export("stream_vector_kernels") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0], count_value = input[1];
    if (mode < 0 || mode > 3 || count_value < 0 || count_value > 128) return -1;
    usz count = (usz)count_value;
    bool has_alpha = mode == 1 || mode == 3;
    usz array_count = mode == 0 || mode == 1 ? 1 : 2;
    usz expected_length = 2 + array_count * count;
    if (has_alpha) expected_length++;
    if (length != expected_length) return -1;

    usz a_start = 2;
    long alpha = 0;
    if (has_alpha) {
        alpha = input[2];
        if (alpha < -1000 || alpha > 1000) return -1;
        a_start = 3;
    }
    usz b_start = a_start + count;
    for (usz index = 0; index < array_count * count; index++)
        if (input[a_start + index] < -1000 || input[a_start + index] > 1000) return -1;

    long staged[128];
    for (usz index = 0; index < count; index++) {
        long a = input[a_start + index];
        long value;
        if (mode == 0) value = a;
        else if (mode == 1) value = alpha * a;
        else if (mode == 2) value = a + input[b_start + index];
        else value = a + alpha * input[b_start + index];
        staged[index] = value;
    }

    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < count; index++) write_i64_le(output, index * 8, staged[index]);
    return (long)output_bytes;
}

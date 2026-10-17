module pkcs7_padding;

long pkcs7_padding(long* input, usz length, uchar* output, usz output_capacity)
        @export("pkcs7_padding") {
    if (input == null || length < 5 || length > 69) return -1;
    long operation = input[0], block_arg = input[1], offset_arg = input[2], data_arg = input[3];
    if (operation < 0 || operation > 2 || block_arg < 1 || block_arg > 16 ||
        data_arg < 1 || data_arg > 64 ||
        (operation == 0 && (offset_arg < 0 || offset_arg > data_arg)) ||
        length != (usz)data_arg + 4) return -1;
    usz block_size = (usz)block_arg, offset = operation == 0 ? (usz)offset_arg : 0, data_length = (usz)data_arg;
    for (usz i = 0; i < data_length; i++)
        if (input[4 + i] < 0 || input[4 + i] > 255) return -1;

    usz padding_count, output_length;
    if (operation == 0) {
        padding_count = block_size - data_length % block_size;
        if (offset + padding_count > data_length) return -1;
        output_length = data_length + 1;
    } else if (operation == 1) {
        if (data_length % block_size != 0) return -1;
        padding_count = (usz)input[3 + data_length];
        if (padding_count == 0 || padding_count > block_size) return -1;
        for (usz i = data_length - padding_count; i < data_length; i++)
            if ((usz)input[4 + i] != padding_count) return -1;
        output_length = data_length - padding_count;
    } else {
        padding_count = (usz)input[3 + data_length];
        long padding_start = (long)data_length - (long)padding_count;
        long invalid_bits = padding_start | ((long)padding_count - 1);
        long padding_check_failed = -(long)((uint)invalid_bits >> 31);
        for (usz i = 0; i < data_length; i++) {
            long difference = (long)i - padding_start;
            uint negative_bit = (uint)difference >> 31;
            long mask = -(long)(1u - negative_bit);
            padding_check_failed |= (input[4 + i] ^ (long)padding_count) & mask;
        }
        if (padding_check_failed != 0) return -1;
        output_length = 1;
    }
    if (output == null || output_capacity < output_length) return -2;
    if (operation == 0) {
        output[0] = (uchar)padding_count;
        for (usz i = 0; i < data_length; i++) {
            usz out_index = i + 1;
            output[out_index] = i >= offset && i < offset + padding_count
                ? (uchar)padding_count : (uchar)input[4 + i];
        }
    } else if (operation == 1) {
        for (usz i = 0; i < output_length; i++) output[i] = (uchar)input[4 + i];
    } else {
        output[0] = (uchar)padding_count;
    }
    return (long)output_length;
}

module move_zeroes;

const usz MAX_LENGTH = 4096;

fn void write_i32_le(char* output, usz index, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long move_zeroes(long* input, usz length, char* output, usz output_capacity)
        @export("move_zeroes") {
    if (length > MAX_LENGTH || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648L || input[index] > 2147483647L) return -1;
    }
    usz output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz write_index = 0;
    for (usz index = 0; index < length; index++) {
        if (input[index] != 0) write_i32_le(output, write_index++, input[index]);
    }
    while (write_index < length) write_i32_le(output, write_index++, 0);
    return (long)length;
}

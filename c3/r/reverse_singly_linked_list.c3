module reverse_singly_linked_list;

const usz MAX_LENGTH = 256;

fn void write_i32_le(char* output, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long reverse_singly_linked_list(int* values, usz length, char* output, usz output_capacity) @export("reverse_singly_linked_list") {
    if (values == null || length > MAX_LENGTH) return -1;
    usz output_bytes = length * 4;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < length; index += 1)
        write_i32_le(output, index, values[length - 1 - index]);
    return (long)output_bytes;
}

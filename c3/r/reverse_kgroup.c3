module reverse_kgroup;

const usz MAX_INPUT_LENGTH = 258;
const usz MAX_LIST_LENGTH = 256;

fn void write_i32_le(char* output, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long reverse_kgroup(int* input, usz length, char* output, usz output_capacity) @export("reverse_kgroup") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    int group_size_value = input[0];
    usz list_length = length - 1;
    if (group_size_value < 1 || group_size_value > 256 || list_length > MAX_LIST_LENGTH) return -1;
    usz group_size = (usz)group_size_value;
    usz output_bytes = list_length * 4;
    if (output == null || output_capacity < output_bytes) return -2;
    usz start = 0;
    while (start + group_size <= list_length) {
        for (usz offset = 0; offset < group_size; offset += 1)
            write_i32_le(output, start + offset, input[1 + start + group_size - 1 - offset]);
        start += group_size;
    }
    while (start < list_length) {
        write_i32_le(output, start, input[1 + start]);
        start += 1;
    }
    return (long)output_bytes;
}

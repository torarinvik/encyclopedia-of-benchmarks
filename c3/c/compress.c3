module compress;

const usz MAX_LENGTH = 64;
const usz BYTES_PER_VALUE = 4;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte += 1) {
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long compress(long* input, usz length, char* output, usz output_capacity)
    @export("compress") {
    if (input == null || length < 1 || length > MAX_LENGTH + 1) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_LENGTH || length != 1 + (usz)count_value) return -1;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index += 1) {
        long value = input[1 + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
    }

    usz maximum_bytes = count * BYTES_PER_VALUE;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == null)) return -2;
    usz result_count = 0;
    long previous = 0;
    for (usz index = 0; index < count; index += 1) {
        long value = input[1 + index];
        if (index == 0 || value != previous) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value);
            result_count += 1;
        }
        previous = value;
    }
    return (long)result_count;
}

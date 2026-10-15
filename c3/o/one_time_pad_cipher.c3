module one_time_pad_cipher;

const usz MAX_TEXT_LENGTH = 1024;

fn long one_time_pad_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("one_time_pad_cipher") {
    if (input == null || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH) return -1;
    long mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;
    if (output_capacity < count || (count > 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        long data = input[2 + index], key = input[2 + count + index];
        if (data < 0 || data > 255 || key < 0 || key > 255) return -1;
        output[index] = (char)(data ^ key);
    }
    return (long)count;
}

module tokenize_string;

fn long tokenize_string(long* input, usz length, char* output, usz capacity)
    @export("tokenize_string") {
    if (input == null || length < 2 || length > 130) return -1;
    if (input[0] < 0 || input[0] > 128) return -1;
    usz text_length = (usz)input[0];
    if (length != text_length + 2) return -1;
    long separator = input[1];
    if (separator != 44 && separator != 46 && separator != 58) return -1;
    usz separator_count = 0;
    for (usz index = 0; index < text_length; index++) {
        long byte = input[index + 2];
        if (byte < 32 || byte > 126) return -1;
        if (byte == separator) separator_count++;
    }
    if (separator_count > 18) return -1;
    usz output_length = text_length + 2;
    if (output == null || capacity < output_length) return -2;
    output[0] = (char)(separator_count + 1);
    for (usz index = 0; index < text_length; index++) {
        long byte = input[index + 2];
        output[index + 1] = byte == separator ? 0 : (char)byte;
    }
    output[output_length - 1] = 0;
    return (long)output_length;
}

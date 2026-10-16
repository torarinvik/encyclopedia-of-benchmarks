module complex_number_multiply;

fn bool parse_component(long* input, usz start, usz end, long* output) {
    bool negative = false;
    if (start < end && input[start] == 45) {
        negative = true;
        start++;
    }
    if (start == end) return false;
    long magnitude = 0;
    for (usz index = start; index < end; index++) {
        if (input[index] < 48 || input[index] > 57) return false;
        long digit = input[index] - 48;
        if (magnitude > (32767 - digit) / 10) return false;
        magnitude = magnitude * 10 + digit;
    }
    output[0] = negative ? -magnitude : magnitude;
    return true;
}

fn bool parse_complex(long* input, usz start, usz length, long* real, long* imaginary) {
    if (length < 4 || length > 64 || input[start + length - 1] != 105) return false;
    usz separator = length;
    for (usz index = 0; index + 1 < length; index++) {
        if (input[start + index] == 43) {
            if (separator != length) return false;
            separator = index;
        }
    }
    if (separator == length) return false;
    return parse_component(input, start, start + separator, real)
        && parse_component(input, start + separator + 1, start + length - 1, imaginary);
}

fn usz decimal_length(long value) {
    usz length = value < 0 ? 1 : 0;
    long magnitude = value < 0 ? -value : value;
    while (true) {
        length++;
        magnitude /= 10;
        if (magnitude == 0) break;
    }
    return length;
}

fn usz append_decimal(long value, char* output, usz index) {
    if (value < 0) {
        output[index] = (char)45;
        index++;
        value = -value;
    }
    usz start = index;
    if (value == 0) {
        output[index] = (char)48;
        return index + 1;
    }
    while (value != 0) {
        output[index] = (char)(48 + value % 10);
        index++;
        value /= 10;
    }
    usz right = index - 1;
    while (start < right) {
        char temporary = output[start];
        output[start] = output[right];
        output[right] = temporary;
        start++;
        right--;
    }
    return index;
}

fn long complex_number_multiply(long* input, usz length, char* output, usz output_capacity)
        @export("complex_number_multiply") {
    if (input == null || length < 2 || length > 130) return -1;
    long raw_left_length = input[0], raw_right_length = input[1];
    if (raw_left_length < 4 || raw_left_length > 64 || raw_right_length < 4 || raw_right_length > 64) return -1;
    usz left_length = (usz)raw_left_length, right_length = (usz)raw_right_length;
    if (length != 2 + left_length + right_length) return -1;
    for (usz index = 2; index < length; index++) if (input[index] < 0 || input[index] > 127) return -1;

    long left_real, left_imaginary, right_real, right_imaginary;
    if (!parse_complex(input, 2, left_length, &left_real, &left_imaginary)
        || !parse_complex(input, 2 + left_length, right_length, &right_real, &right_imaginary)) return -1;

    long real = left_real * right_real - left_imaginary * right_imaginary;
    long imaginary = left_real * right_imaginary + left_imaginary * right_real;
    usz needed = decimal_length(real) + decimal_length(imaginary) + 2;
    if (output == null || output_capacity < needed) return -2;

    usz written = append_decimal(real, output, 0);
    output[written] = (char)43;
    written++;
    written = append_decimal(imaginary, output, written);
    output[written] = (char)105;
    written++;
    return (long)written;
}

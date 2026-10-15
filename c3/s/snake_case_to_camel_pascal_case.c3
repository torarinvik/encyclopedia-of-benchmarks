module snake_case_to_camel_pascal_case;

const MAX_LENGTH = 256;

fn long snake_case_to_camel_pascal_case(long* input, usz length, char* output, usz capacity) @export("snake_case_to_camel_pascal_case") {
    if (input == null || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] != 0 && input[0] != 1) return -1;

    usz input_length = length - 1;
    usz output_length = 0;
    for (usz i = 0; i < input_length; i++) {
        long value = input[i + 1];
        if (value == 95) {
            if (i == 0 || i + 1 == input_length || input[i] == 95) return -1;
        } else if (!((value >= 97 && value <= 122) || (value >= 48 && value <= 57))) {
            return -1;
        } else {
            output_length++;
        }
    }
    if (capacity < output_length || output == null) return -2;

    usz position = 0;
    bool capitalize = input[0] == 1;
    for (usz i = 0; i < input_length; i++) {
        long value = input[i + 1];
        if (value == 95) {
            capitalize = true;
            continue;
        }
        if (capitalize && value >= 97 && value <= 122) value -= 32;
        output[position++] = (char)value;
        capitalize = false;
    }
    return (long)output_length;
}

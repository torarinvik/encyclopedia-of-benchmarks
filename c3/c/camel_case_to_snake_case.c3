module camel_case_to_snake_case;

const MAX_LENGTH = 256;

fn long camel_case_to_snake_case(long* input, usz length, char* output, usz capacity) @export("camel_case_to_snake_case") {
    if (length == 0 || length > MAX_LENGTH || input == null) return -1;

    usz output_length = 0;
    for (usz i = 0; i < length; i++) {
        long value = input[i];
        if (value >= 65 && value <= 90) {
            if (i > 0) output_length++;
        } else if (value < 97 || value > 122) {
            return -1;
        }
        output_length++;
    }
    if (capacity < output_length || output == null) return -2;

    usz position = 0;
    for (usz i = 0; i < length; i++) {
        long value = input[i];
        if (value >= 65 && value <= 90) {
            if (i > 0) output[position++] = '_';
            output[position++] = (char)(value + 32);
        } else {
            output[position++] = (char)value;
        }
    }
    return (long)output_length;
}

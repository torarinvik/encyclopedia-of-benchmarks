module large_number;

const usz MAX_DIGITS = 64;
const usz MAX_INPUT_LENGTH = 130;
const usz MAX_PARSEABLE_INPUT_LENGTH = 131;
const usz MAX_OUTPUT_BYTES = 65;

fn bool is_decimal_digit(long value) {
    return value >= 48 && value <= 57;
}

fn long large_number_add(long* input, usz input_length, char* output,
                         usz output_capacity) @export("large_number_add") {
    if (input == null || input_length < 2 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    long left_length_value = input[0];
    long right_length_value = input[1];
    if (left_length_value < 1 || left_length_value > (long)MAX_DIGITS ||
        right_length_value < 1 || right_length_value > (long)MAX_DIGITS) return -1;

    usz left_length = (usz)left_length_value;
    usz right_length = (usz)right_length_value;
    if (input_length != 2 + left_length + right_length) return -1;

    usz left_start = 2;
    usz right_start = left_start + left_length;
    for (usz i = 0; i < left_length; i++) {
        if (!is_decimal_digit(input[left_start + i])) return -1;
    }
    for (usz i = 0; i < right_length; i++) {
        if (!is_decimal_digit(input[right_start + i])) return -1;
    }
    if ((left_length > 1 && input[left_start] == 48) ||
        (right_length > 1 && input[right_start] == 48)) return -1;

    char[MAX_OUTPUT_BYTES] reversed;
    usz result_length = 0;
    usz index = 0;
    usz max_length = left_length > right_length ? left_length : right_length;
    long carry = 0;
    while (index < max_length || carry != 0) {
        long total = carry;
        if (index < right_length) {
            total += input[right_start + right_length - index - 1] - 48;
        }
        if (index < left_length) {
            total += input[left_start + left_length - index - 1] - 48;
        }
        reversed[result_length++] = (char)(48 + total % 10);
        carry = total / 10;
        index++;
    }

    char[MAX_OUTPUT_BYTES] result;
    for (usz i = 0; i < result_length; i++) {
        result[i] = reversed[result_length - i - 1];
    }

    if (output == null || output_capacity < result_length) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = result[i];
    return (long)result_length;
}

module add_two_numbers;

const usz MAX_DIGITS = 1024;
const usz MAX_INPUT_LENGTH = 2050;

fn long add_two_numbers(long* input, usz length, char* output, usz output_capacity)
        @export("add_two_numbers") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_DIGITS || input[1] < 0 || input[1] > (long)MAX_DIGITS) return -1;
    usz first_length = (usz)input[0];
    usz second_length = (usz)input[1];
    if (length != first_length + second_length + 2) return -1;
    for (usz index = 0; index < first_length + second_length; index++) {
        if (input[index + 2] < 0 || input[index + 2] > 9) return -1;
    }

    usz digit_count = first_length > second_length ? first_length : second_length;
    char[MAX_DIGITS + 1] digits;
    usz result_length = 0;
    long carry = 0;
    for (usz index = 0; index < digit_count || carry != 0; index++) {
        long first = index < first_length ? input[index + 2] : 0;
        long second = index < second_length ? input[index + 2 + first_length] : 0;
        long sum = first + second + carry;
        digits[result_length++] = (char)(sum % 10);
        carry = sum / 10;
    }
    if (output_capacity < result_length || (result_length != 0 && output == null)) return -2;
    for (usz index = 0; index < result_length; index++) output[index] = digits[index];
    return (long)result_length;
}

module string_fibonacci;

const usz MAX_N = 256;
const usz DECIMAL_CAPACITY = 80;

fn usz add_decimal(char* left, usz left_length, char* right, usz right_length, char* result) {
    char[DECIMAL_CAPACITY] reversed;
    usz length = 0;
    int carry = 0;
    while (left_length > 0 || right_length > 0 || carry != 0) {
        int left_digit = left_length > 0 ? left[--left_length] - '0' : 0;
        int right_digit = right_length > 0 ? right[--right_length] - '0' : 0;
        int sum = left_digit + right_digit + carry;
        reversed[length++] = (char)('0' + sum % 10);
        carry = sum / 10;
    }
    for (usz i = 0; i < length; ++i) result[i] = reversed[length - 1 - i];
    result[length] = '\0';
    return length;
}

fn long string_fibonacci(long* input, usz length, char* output, usz capacity)
        @export("string_fibonacci") {
    if (input == null || length != 1) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N) return -1;

    char[DECIMAL_CAPACITY] fib_minus_one = "1";
    char[DECIMAL_CAPACITY] fib_minus_two = "0";
    usz minus_one_length = 1;
    usz minus_two_length = 1;
    for (usz i = 0; i < (usz)input[0]; ++i) {
        char[DECIMAL_CAPACITY] sum;
        usz sum_length = add_decimal(&fib_minus_one[0], minus_one_length,
                                     &fib_minus_two[0], minus_two_length, &sum[0]);
        for (usz j = 0; j < minus_one_length; ++j) fib_minus_two[j] = fib_minus_one[j];
        minus_two_length = minus_one_length;
        for (usz j = 0; j < sum_length; ++j) fib_minus_one[j] = sum[j];
        fib_minus_one[sum_length] = '\0';
        minus_one_length = sum_length;
    }

    if (output == null || capacity < minus_two_length) return -2;
    for (usz i = 0; i < minus_two_length; ++i) output[i] = fib_minus_two[i];
    return (long)minus_two_length;
}

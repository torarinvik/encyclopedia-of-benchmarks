module find_second_largest_element;

const long INVALID_RESULT = -9223372036854775807L - 1;
const long INT32_MIN_VALUE = -2147483648;
const long INT32_MAX_VALUE = 2147483647;

fn long find_second_largest_element(long* input, usz length) @export("find_second_largest_element") {
    if (input == null || length < 3 || length > 10001) return INVALID_RESULT;
    long n = input[0];
    if (n < 2 || n > 10000 || length != (usz)n + 1) return INVALID_RESULT;
    long largest = INT32_MIN_VALUE;
    for (usz i = 0; i < (usz)n; i++) {
        long value = input[i + 1];
        if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE) return INVALID_RESULT;
        if (value > largest) largest = value;
    }
    long second = INT32_MIN_VALUE - 1;
    for (usz i = 0; i < (usz)n; i++) {
        long value = input[i + 1];
        if (value < largest && value > second) second = value;
    }
    return second == INT32_MIN_VALUE - 1 ? INVALID_RESULT : second;
}

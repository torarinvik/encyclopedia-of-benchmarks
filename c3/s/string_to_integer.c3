module string_to_integer;

const MAX_INPUT_LENGTH = 4096;
const INT32_MAX_VALUE = 2147483647;
const INT32_MIN_MAGNITUDE = 2147483648;

fn long string_to_integer(long* input, usz length) @export("string_to_integer") {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == null)) return -2;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 127) return -2;
    }

    usz index = 0;
    while (index < length && input[index] == ' ') index++;
    bool negative = false;
    if (index < length && (input[index] == '+' || input[index] == '-')) {
        negative = input[index] == '-';
        index++;
    }
    long limit = negative ? INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
    long magnitude = 0;
    while (index < length && input[index] >= '0' && input[index] <= '9') {
        long digit = input[index] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
        magnitude = magnitude * 10 + digit;
        index++;
    }
    return negative ? -magnitude : magnitude;
}

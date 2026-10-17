module my_atoi;

const usz MAX_INPUT_LENGTH = 256;
const long INT32_MAX_VALUE = 2147483647;
const long INT32_MIN_MAGNITUDE = 2147483648;
const long INVALID_RESULT = -9223372036854775807L - 1;

fn long my_atoi(long* input, usz length) @export("my_atoi") {
    if (input == null) return 0;
    if (length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127) return INVALID_RESULT;

    usz start = 0, end = length;
    while (start < end && input[start] <= 32) start++;
    while (end > start && input[end - 1] <= 32) end--;
    if (start == end) return 0;

    bool negative = false;
    if (input[start] == 43 || input[start] == 45) {
        negative = input[start] == 45;
        start++;
    }
    long limit = negative ? INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
    long magnitude = 0;
    while (start < end && input[start] >= 48 && input[start] <= 57) {
        long digit = input[start] - 48;
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
        magnitude = magnitude * 10 + digit;
        start++;
    }
    return negative ? -magnitude : magnitude;
}

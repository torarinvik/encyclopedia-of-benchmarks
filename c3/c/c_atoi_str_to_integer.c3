module c_atoi_str_to_integer;

const MAX_INPUT_LENGTH = 4096;
const INT32_MAX_VALUE = 2147483647;
const INT32_MIN_MAGNITUDE = 2147483648;

fn bool is_ascii_space(long value) {
    return (value >= 9 && value <= 13) || value == 32;
}

// Parse C ASCII whitespace, optional sign, and the initial decimal run; NUL terminates input.
fn long c_atoi_str_to_integer(long* input, usz length) @export("c_atoi_str_to_integer") {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == null)) return -2;
    for (usz position = 0; position < length; position++) {
        if (input[position] < 0 || input[position] > 127) return -2;
    }
    usz index = 0;
    while (index < length && input[index] != 0 && is_ascii_space(input[index])) index++;
    bool negative = false;
    if (index < length && input[index] != 0 && (input[index] == '+' || input[index] == '-')) {
        negative = input[index] == '-';
        index++;
    }
    long limit = negative ? INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
    long magnitude = 0;
    while (index < length && input[index] != 0 && input[index] >= '0' && input[index] <= '9') {
        long digit = input[index] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
        magnitude = magnitude * 10 + digit;
        index++;
    }
    return negative ? -magnitude : magnitude;
}

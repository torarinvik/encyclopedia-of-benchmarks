/// Parse C ASCII whitespace, an optional sign, initial decimal digits, and NUL termination.
const MAX_INPUT_LENGTH: usize = 4096;
const INT32_MAX_VALUE: i64 = 2147483647;
const INT32_MIN_MAGNITUDE: i64 = 2147483648;

export fn c_atoi_str_to_integer(input: [*]const i64, length: usize) i64 {
    if (length > MAX_INPUT_LENGTH) return -2;
    for (0..length) |position| {
        if (input[position] < 0 or input[position] > 127) return -2;
    }
    var index: usize = 0;
    while (index < length and input[index] != 0 and ((input[index] >= 9 and input[index] <= 13) or input[index] == 32)) : (index += 1) {}
    var negative = false;
    if (index < length and input[index] != 0 and (input[index] == 43 or input[index] == 45)) {
        negative = input[index] == 45;
        index += 1;
    }
    const limit = if (negative) INT32_MIN_MAGNITUDE else INT32_MAX_VALUE;
    var magnitude: i64 = 0;
    while (index < length and input[index] != 0 and input[index] >= 48 and input[index] <= 57) : (index += 1) {
        const digit = input[index] - 48;
        if (magnitude > @divTrunc(limit, 10) or
            (magnitude == @divTrunc(limit, 10) and digit > @rem(limit, 10))) {
            return if (negative) -INT32_MIN_MAGNITUDE else INT32_MAX_VALUE;
        }
        magnitude = magnitude * 10 + digit;
    }
    return if (negative) -magnitude else magnitude;
}

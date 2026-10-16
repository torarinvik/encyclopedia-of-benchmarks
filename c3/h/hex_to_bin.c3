module hex_to_bin;

const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long hex_digit(long byte)
{
    if (byte >= 48 && byte <= 57) return byte - 48;
    if (byte >= 65 && byte <= 70) return byte - 65 + 10;
    if (byte >= 97 && byte <= 102) return byte - 97 + 10;
    return -1;
}

fn long hex_to_bin(long* input, usz length) @export("hex_to_bin")
{
    if (input == null || length < 1 || length > 5) return INVALID_RESULT;
    usz start = 0;
    long sign = 1;
    if (input[0] == 45) {
        sign = -1;
        start = 1;
    }
    if (length - start < 1 || length - start > 4) return INVALID_RESULT;

    long value = 0;
    for (usz index = start; index < length; index++) {
        long digit = hex_digit(input[index]);
        if (digit < 0) return INVALID_RESULT;
        value = value * 16 + digit;
    }
    if (value == 0) return INVALID_RESULT;

    long decimal_binary_digits = 0, place = 1;
    while (value > 0) {
        decimal_binary_digits += (value % 2) * place;
        value /= 2;
        if (value > 0) place *= 10;
    }
    return sign * decimal_binary_digits;
}

module hexa_decimal_to_decimal;

const MAX_INPUT_LENGTH: usz = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usz = 65;
const long INVALID_RESULT = -2147483649;
const ulong UINT32_MODULUS = 4294967296;

fn long hexa_decimal_to_decimal(long* input, usz length) @export("hexa_decimal_to_decimal") {
    if (length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length == 0) return 0;
    if (length > MAX_INPUT_LENGTH || input == null) return INVALID_RESULT;

    ulong accumulator = 0;
    for (usz index = 0; index < length; index++) {
        long code = input[index];
        long digit;
        if (code >= 48 && code <= 57) digit = code - 48;
        else if (code >= 65 && code <= 70) digit = code - 55;
        else if (code >= 97 && code <= 102) digit = code - 87;
        else return INVALID_RESULT;
        accumulator = (accumulator * 16 + (ulong)digit) % UINT32_MODULUS;
    }
    if (accumulator <= 2147483647) return (long)accumulator;
    return (long)accumulator - (long)UINT32_MODULUS;
}

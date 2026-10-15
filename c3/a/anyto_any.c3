module anyto_any;

const long MAX_ENCODED_VALUE = 999999999;

fn long anyto_any(long* input, usz length) @export("anyto_any") {
    if (input == null || length != 3) return -1;
    long encoded = input[0];
    long source_base = input[1];
    long destination_base = input[2];
    if (encoded < 0 || encoded > MAX_ENCODED_VALUE || source_base < 2 || source_base > 10 ||
        destination_base < 2 || destination_base > 10) return -1;

    long decimal_value = 0;
    long source_multiplier = 1;
    while (encoded > 0) {
        long digit = encoded % 10;
        if (digit >= source_base) return -1;
        decimal_value += digit * source_multiplier;
        source_multiplier *= source_base;
        encoded /= 10;
    }

    long result = 0;
    long destination_multiplier = 1;
    while (decimal_value > 0) {
        long digit = decimal_value % destination_base;
        result += digit * destination_multiplier;
        decimal_value /= destination_base;
        if (decimal_value > 0) {
            if (destination_multiplier > MAX_ENCODED_VALUE / 10) return -1;
            destination_multiplier *= 10;
        }
    }
    return result;
}

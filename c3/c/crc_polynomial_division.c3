module crc_polynomial_division;

fn long crc_polynomial_division(long* input, usz length, char* output, usz capacity)
    @export("crc_polynomial_division") {
    if (input == null || length < 3 || length > 3 + 79 + 16) return -1;
    long operation = input[0];
    long raw_message_length = input[1];
    long raw_polynomial_length = input[2];
    if (operation < 0 || operation > 1 || raw_message_length < 1
        || (operation == 0 && raw_message_length > 64) || (operation == 1 && raw_message_length > 79)
        || raw_polynomial_length < 2 || raw_polynomial_length > 16) return -1;
    usz message_length = (usz)raw_message_length;
    usz polynomial_length = (usz)raw_polynomial_length;
    if (length != 3 + message_length + polynomial_length) return -1;

    char[79] message;
    char[16] polynomial;
    char[79] dividend;
    char[16] remainder;
    for (usz i = 0; i < message_length; i += 1) {
        if (input[3+i] < 0 || input[3+i] > 1) return -1;
        message[i] = (char)input[3+i];
    }
    for (usz i = 0; i < polynomial_length; i += 1) {
        long bit = input[3+message_length+i];
        if (bit < 0 || bit > 1) return -1;
        polynomial[i] = (char)bit;
    }
    if (polynomial[0] != 1 || polynomial[polynomial_length-1] != 1) return -1;

    usz dividend_length = message_length;
    for (usz i = 0; i < message_length; i += 1) dividend[i] = message[i];
    if (operation == 0) {
        for (usz i = 0; i + 1 < polynomial_length; i += 1) dividend[dividend_length++] = 0;
    }
    usz remainder_length = 0;
    usz cursor = 0;
    while (cursor < dividend_length) {
        while (remainder_length < polynomial_length && cursor < dividend_length) {
            remainder[remainder_length++] = dividend[cursor++];
        }
        if (remainder_length == polynomial_length) {
            if (remainder[0] == 1) {
                for (usz i = 0; i < polynomial_length; i += 1) remainder[i] ^= polynomial[i];
            }
            usz leading_zeroes = 0;
            while (leading_zeroes < remainder_length && remainder[leading_zeroes] == 0) {
                leading_zeroes += 1;
            }
            for (usz i = leading_zeroes; i < remainder_length; i += 1) {
                remainder[i-leading_zeroes] = remainder[i];
            }
            remainder_length -= leading_zeroes;
        }
    }

    usz output_length;
    if (operation == 0) {
        output_length = message_length + polynomial_length - 1;
    }
    else {
        char nonzero = 0;
        for (usz i = 0; i < remainder_length; i += 1) nonzero |= remainder[i];
        remainder[0] = (char)(nonzero != 0);
        output_length = 1;
    }
    if (output == null || capacity < output_length) return -2;
    if (operation == 0) {
        for (usz i = 0; i < message_length; i += 1) output[i] = message[i];
        usz degree = polynomial_length - 1;
        usz leading_zeroes = degree - remainder_length;
        for (usz i = 0; i < leading_zeroes; i += 1) output[message_length+i] = 0;
        for (usz i = 0; i < remainder_length; i += 1) {
            output[message_length+leading_zeroes+i] = remainder[i];
        }
    } else {
        output[0] = remainder[0];
    }
    return (long)output_length;
}

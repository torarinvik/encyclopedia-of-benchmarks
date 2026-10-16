#include <stddef.h>
#include <stdint.h>

int64_t crc_polynomial_division(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > 3 + 79 + 16) return -1;
    const int64_t operation = input[0];
    const int64_t raw_message_length = input[1];
    const int64_t raw_polynomial_length = input[2];
    if (operation < 0 || operation > 1 || raw_message_length < 1
        || (operation == 0 && raw_message_length > 64) || (operation == 1 && raw_message_length > 79)
        || raw_polynomial_length < 2 || raw_polynomial_length > 16) return -1;
    const size_t message_length = (size_t)raw_message_length;
    const size_t polynomial_length = (size_t)raw_polynomial_length;
    if (length != 3 + message_length + polynomial_length) return -1;

    uint8_t message[79], polynomial[16], dividend[79], remainder[16];
    for (size_t i = 0; i < message_length; ++i) {
        if (input[3 + i] < 0 || input[3 + i] > 1) return -1;
        message[i] = (uint8_t)input[3 + i];
    }
    for (size_t i = 0; i < polynomial_length; ++i) {
        const int64_t bit = input[3 + message_length + i];
        if (bit < 0 || bit > 1) return -1;
        polynomial[i] = (uint8_t)bit;
    }
    if (polynomial[0] != 1 || polynomial[polynomial_length - 1] != 1) return -1;

    size_t dividend_length = message_length;
    for (size_t i = 0; i < message_length; ++i) dividend[i] = message[i];
    if (operation == 0) {
        for (size_t i = 0; i + 1 < polynomial_length; ++i) dividend[dividend_length++] = 0;
    }

    size_t remainder_length = 0;
    size_t cursor = 0;
    while (cursor < dividend_length) {
        while (remainder_length < polynomial_length && cursor < dividend_length)
            remainder[remainder_length++] = dividend[cursor++];
        if (remainder_length == polynomial_length) {
            if (remainder[0] == 1) {
                for (size_t i = 0; i < polynomial_length; ++i) remainder[i] ^= polynomial[i];
            }
            size_t leading_zeroes = 0;
            while (leading_zeroes < remainder_length && remainder[leading_zeroes] == 0) ++leading_zeroes;
            for (size_t i = leading_zeroes; i < remainder_length; ++i) remainder[i - leading_zeroes] = remainder[i];
            remainder_length -= leading_zeroes;
        }
    }

    size_t output_length;
    if (operation == 0) output_length = message_length + polynomial_length - 1;
    else {
        uint8_t nonzero = 0;
        for (size_t i = 0; i < remainder_length; ++i) nonzero |= remainder[i];
        remainder[0] = nonzero != 0;
        output_length = 1;
    }
    if (output == NULL || capacity < output_length) return -2;
    if (operation == 0) {
        for (size_t i = 0; i < message_length; ++i) output[i] = message[i];
        const size_t degree = polynomial_length - 1;
        const size_t leading_zeroes = degree - remainder_length;
        for (size_t i = 0; i < leading_zeroes; ++i) output[message_length + i] = 0;
        for (size_t i = 0; i < remainder_length; ++i)
            output[message_length + leading_zeroes + i] = remainder[i];
    } else output[0] = remainder[0];
    return (int64_t)output_length;
}

#include <stddef.h>
#include <stdint.h>

#define MAX_PACKED_INPUT_LENGTH 37
#define MAX_PARSEABLE_INPUT_LENGTH 38
#define MAX_OUTPUT_LENGTH 35

int64_t ipconverter(const int64_t *input, size_t length,
                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t mode = input[0], payload_length_value = input[1];
    if ((mode != 0 && mode != 1) || payload_length_value < 0 || payload_length_value > MAX_OUTPUT_LENGTH) return -1;
    const size_t payload_length = (size_t)payload_length_value;
    if (length != payload_length + 2) return -1;

    int64_t octets[4] = {0, 0, 0, 0};
    size_t position = 0;
    if (mode == 0) {
        if (payload_length < 7 || payload_length > 15) return -1;
        for (size_t octet = 0; octet < 4; ++octet) {
            int digits = 0;
            int64_t value = 0;
            while (position < payload_length && input[2 + position] != 46) {
                const int64_t byte = input[2 + position];
                if (digits == 3 || byte < 48 || byte > 57) return -1;
                value = value * 10 + byte - 48;
                if (value > 255) return -1;
                ++digits;
                ++position;
            }
            if (digits == 0) return -1;
            octets[octet] = value;
            if (octet < 3) {
                if (position >= payload_length || input[2 + position] != 46) return -1;
                ++position;
            } else if (position != payload_length) {
                return -1;
            }
        }
    } else {
        if (payload_length != 35) return -1;
        for (size_t octet = 0; octet < 4; ++octet) {
            int64_t value = 0;
            for (int bit = 0; bit < 8; ++bit) {
                const int64_t byte = input[2 + position++];
                if (byte != 48 && byte != 49) return -1;
                value = value * 2 + byte - 48;
            }
            octets[octet] = value;
            if (octet < 3) {
                if (input[2 + position++] != 46) return -1;
            }
        }
        if (position != payload_length) return -1;
    }

    size_t output_length = mode == 0 ? 35 : 3;
    if (mode == 1) {
        for (size_t i = 0; i < 4; ++i)
            output_length += octets[i] >= 100 ? 2 : octets[i] >= 10 ? 1 : 0;
    }
    if (capacity < output_length || output == NULL) return -2;

    position = 0;
    for (size_t octet = 0; octet < 4; ++octet) {
        if (mode == 0) {
            for (int bit = 7; bit >= 0; --bit)
                output[position++] = (uint8_t)('0' + ((octets[octet] >> bit) & 1));
        } else {
            int64_t value = octets[octet];
            if (value >= 100) { output[position++] = (uint8_t)('0' + value / 100); value %= 100; }
            if (value >= 10) { output[position++] = (uint8_t)('0' + value / 10); value %= 10; }
            output[position++] = (uint8_t)('0' + value);
        }
        if (octet < 3) output[position++] = '.';
    }
    return (int64_t)position;
}

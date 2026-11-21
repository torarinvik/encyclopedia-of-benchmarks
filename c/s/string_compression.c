#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64

int64_t string_compression(const int64_t *input, size_t length, uint8_t *output,
                           size_t output_capacity) {
    if (length == 0) return 0;
    if (length == 1) {
        if (input == NULL) return -1;
        const uint64_t value = (uint64_t)input[0];
        if (value > 127) return -1;
        if (output_capacity == 0 || output == NULL) return -2;
        output[0] = (uint8_t)value;
        return 1;
    }
    if (input == NULL || length > MAX_INPUT_LENGTH) return -1;

    if (length == 2) {
        const uint64_t first = (uint64_t)input[0];
        const uint64_t second = (uint64_t)input[1];
        if ((first | second) > 127) return -1;
        if (output_capacity < 2 || output == NULL) return -2;
        output[0] = (uint8_t)first;
        output[1] = first == second ? 50 : (uint8_t)second;
        return 2;
    }

    /* A set bit above bit 6 marks an invalid ASCII code unit. */
    if (length >= 8) {
        uint64_t combined = 0;
        for (size_t index = 0; index < length; ++index)
            combined |= (uint64_t)input[index];
        if (combined > 127) return -1;
    } else {
        for (size_t remaining = length; remaining != 0;)
            if ((uint64_t)input[--remaining] > 127) return -1;
    }

    if (output == NULL) return -2;
    /* Each run encodes to at most as many bytes as it consumes. */
    if (output_capacity < length) {
        size_t encoded_length = 0;
        for (size_t index = 0; index < length;) {
            size_t end = index + 1;
            while (end < length && input[end] == input[index]) ++end;
            const size_t count = end - index;
            encoded_length += 1 + (count > 1 ? (count >= 10 ? 2 : 1) : 0);
            index = end;
        }
        if (output_capacity < encoded_length) return -2;
    }

    size_t write_index = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        size_t remaining = length - end;
        while (remaining != 0 && input[end] == input[index]) {
            ++end;
            --remaining;
        }
        const size_t count = end - index;
        output[write_index++] = (uint8_t)input[index];
        if (count > 1) {
            if (count < 10) {
                output[write_index++] = (uint8_t)(48 + count);
            } else {
                /* This reciprocal gives the exact quotient for counts up to 64. */
                const uint32_t digits = (uint32_t)count;
                const uint32_t tens = (digits * 103) >> 10;
                output[write_index++] = (uint8_t)(48 + tens);
                output[write_index++] = (uint8_t)(48 + digits - tens * 10);
            }
        }
        index = end;
    }
    return (int64_t)write_index;
}

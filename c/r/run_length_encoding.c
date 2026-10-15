/* Encode runs as an unambiguous decimal count followed by an ASCII byte. */
#include <stddef.h>
#include <stdint.h>

int64_t run_length_encoding(const int64_t *input, size_t length, uint8_t *output,
                            size_t output_capacity)
{
    if (length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127 ||
            (input[index] >= 48 && input[index] <= 57)) return -1;

    size_t encoded_length = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const size_t count = end - index;
        encoded_length += count >= 10 ? 3 : 2;
        index = end;
    }
    if (output_capacity < encoded_length) return -2;

    size_t write_index = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const size_t count = end - index;
        if (count >= 10) output[write_index++] = (uint8_t)(48 + count / 10);
        output[write_index++] = (uint8_t)(48 + count % 10);
        output[write_index++] = (uint8_t)input[index];
        index = end;
    }
    return (int64_t)write_index;
}

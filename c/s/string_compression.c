#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64

int64_t string_compression(const int64_t *input, size_t length, uint8_t *output,
                           size_t output_capacity) {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;

    size_t encoded_length = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const size_t count = end - index;
        encoded_length += 1 + (count > 1 ? (count >= 10 ? 2 : 1) : 0);
        index = end;
    }
    if (output_capacity < encoded_length || (encoded_length != 0 && output == NULL)) return -2;

    size_t write_index = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const size_t count = end - index;
        output[write_index++] = (uint8_t)input[index];
        if (count > 1) {
            if (count >= 10) output[write_index++] = (uint8_t)(48 + count / 10);
            output[write_index++] = (uint8_t)(48 + count % 10);
        }
        index = end;
    }
    return (int64_t)write_index;
}

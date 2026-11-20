#include <stddef.h>
#include <stdint.h>

#define COBS_MAX_WORDS 257
#define COBS_MAX_PAYLOAD 255
#define COBS_MAX_OUTPUT 257

int64_t consistent_overhead_byte_stuffing(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > COBS_MAX_WORDS) return -1;
    const int64_t payload_length_value = input[0];
    if (payload_length_value < 0 || payload_length_value > COBS_MAX_PAYLOAD) return -1;
    const size_t payload_length = (size_t)payload_length_value;
    if (length != payload_length + 1) return -1;
    for (size_t index = 0; index < payload_length; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;

    uint8_t staged[COBS_MAX_OUTPUT] = {0};
    size_t written = 1;
    size_t code_position = 0;
    unsigned code = 1;
    int omitted_terminal_code = 0;
    for (size_t index = 0; index < payload_length; ++index) {
        const uint8_t byte = (uint8_t)input[index + 1];
        if (byte == 0) {
            staged[code_position] = (uint8_t)code;
            code_position = written++;
            code = 1;
        } else {
            staged[written++] = byte;
            ++code;
            if (code == 255) {
                staged[code_position] = 255;
                if (index + 1 == payload_length) {
                    omitted_terminal_code = 1;
                    break;
                }
                code_position = written++;
                code = 1;
            }
        }
    }
    if (!omitted_terminal_code) staged[code_position] = (uint8_t)code;

    if (output == NULL || capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = staged[index];
    return (int64_t)written;
}

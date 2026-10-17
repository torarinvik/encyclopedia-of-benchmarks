#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 292
#define MAX_PIXELS 256
#define MAX_MESSAGE_BYTES 32

int64_t lsb_image_steganography(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > MAX_MESSAGE_BYTES) return -1;
    size_t rows = (size_t)input[0], columns = (size_t)input[1], message_length = (size_t)input[2];
    size_t pixel_count = rows * columns;
    if (message_length * 8 > pixel_count || length != 3 + pixel_count + message_length) return -1;
    for (size_t i = 0; i < pixel_count; ++i) if (input[3 + i] < 0 || input[3 + i] > 254) return -1;
    for (size_t i = 0; i < message_length; ++i) if (input[3 + pixel_count + i] < 0 || input[3 + pixel_count + i] > 127) return -1;
    if (output == NULL || capacity < pixel_count) return -2;
    for (size_t i = 0; i < pixel_count; ++i) output[i] = (uint8_t)input[3 + i];
    size_t bit_index = 0;
    for (size_t i = 0; i < message_length; ++i) {
        unsigned int byte = (unsigned int)input[3 + pixel_count + i];
        for (int shift = 7; shift >= 0; --shift) {
            unsigned int bit = (byte >> shift) & 1U;
            unsigned int pixel = output[bit_index];
            output[bit_index] = (uint8_t)(pixel + ((pixel & 1U) ^ bit));
            ++bit_index;
        }
    }
    return (int64_t)pixel_count;
}

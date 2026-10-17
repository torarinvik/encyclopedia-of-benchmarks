#include <stddef.h>
#include <stdint.h>

int64_t long_utils(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    if (input[0] < 0 || input[0] > 3 || input[2] < 0 || input[2] > 63) return -1;
    if (output == NULL || capacity < 8) return -2;
    const uint64_t bits = (uint64_t)input[1];
    const unsigned distance = (unsigned)input[2];
    uint64_t rotated = bits;
    if (distance != 0) {
        if (input[0] < 2)
            rotated = (bits << distance) | (bits >> (64 - distance));
        else
            rotated = (bits >> distance) | (bits << (64 - distance));
    }
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(rotated >> (8 * byte));
    return 8;
}

/* Clean-room bounded digit-to-segment profile for the BEEBS lcdnum source. */
#include <stddef.h>
#include <stdint.h>

#define LCDNUM_INPUT_BYTES 5
#define LCDNUM_OUTPUT_BYTES 5

static const uint8_t SEGMENT_MASKS[16] = {
    0x00, 0x24, 0x5D, 0x6D, 0x2E, 0x5D, 0x7B, 0x25,
    0x7F, 0x6F, 0x3F, 0x7A, 0x53, 0x7C, 0x5B, 0x1B
};

int64_t beebs_lcdnum(const int64_t *values, size_t length,
                     uint8_t *output, size_t capacity) {
    if (values == NULL || length != LCDNUM_INPUT_BYTES) return -1;
    for (size_t i = 0; i < LCDNUM_INPUT_BYTES; ++i)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (output == NULL || capacity < LCDNUM_OUTPUT_BYTES) return -2;
    for (size_t i = 0; i < LCDNUM_INPUT_BYTES; ++i)
        output[i] = SEGMENT_MASKS[(uint8_t)values[i] & 0x0F];
    return LCDNUM_OUTPUT_BYTES;
}

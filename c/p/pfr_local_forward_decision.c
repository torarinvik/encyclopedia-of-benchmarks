#include <stddef.h>
#include <stdint.h>

#define DRAW_COUNT 1000000
#define MAX_ANGLE 180000000
#define FORCE_FORWARD_ANGLE 134000000

static void put64(uint8_t *out, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t pfr_local_forward_decision(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t angle = input[0], draw = input[1];
    if (angle < 0 || angle > MAX_ANGLE || draw < 0 || draw >= DRAW_COUNT) return -1;
    const int64_t forward = angle >= FORCE_FORWARD_ANGLE || 180 * draw < angle;
    if (output == NULL || capacity < 8) return -2;
    put64(output, forward);
    return 8;
}

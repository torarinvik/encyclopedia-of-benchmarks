#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { CORDIC_OUTPUT_BYTES = 24 };
static const int64_t CORDIC_ANGLES[15] = {
    785398163, 463647609, 244978663, 124354995, 62418810,
    31239833, 15623729, 7812341, 3906230, 1953123,
    976562, 488281, 244141, 122070, 61035,
};

static int64_t cordic_shift_floor(int64_t value, unsigned shift) {
    if (shift == 0) return value;
    const int64_t divisor = INT64_C(1) << shift;
    if (value >= 0) return value / divisor;
    return -((-value + divisor - 1) / divisor);
}

static void cordic_store_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits = 0;
    memcpy(&bits, &value, sizeof(bits));
    for (unsigned byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t cordic_rotation_fixed_point(const int64_t *values, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > 3) return -1;
    if (length != 2) return -1;
    const int64_t angle = values[0];
    const int64_t stages = values[1];
    if (angle < -INT64_C(3141592653) || angle > INT64_C(3141592653) ||
        stages < 1 || stages > 16) return -1;
    if (output == NULL || output_capacity < CORDIC_OUTPUT_BYTES) return -2;

    int64_t x = INT64_C(1000000000);
    int64_t y = 0;
    int64_t z = angle;
    int64_t direction = z >= 0 ? 1 : -1;
    if (direction > 0) {
        const int64_t old_x = x;
        x = -y;
        y = old_x;
    } else {
        const int64_t old_x = x;
        x = y;
        y = -old_x;
    }
    z -= direction * INT64_C(1570796327);

    for (unsigned shift = 0; shift < (unsigned)(stages - 1); ++shift) {
        direction = z >= 0 ? 1 : -1;
        const int64_t old_x = x;
        const int64_t old_y = y;
        x = old_x - direction * cordic_shift_floor(old_y, shift);
        y = old_y + direction * cordic_shift_floor(old_x, shift);
        z -= direction * CORDIC_ANGLES[shift];
    }

    uint8_t staged[CORDIC_OUTPUT_BYTES];
    const double scale = 1000000000.0;
    cordic_store_f64_le(staged, 0, (double)x / scale);
    cordic_store_f64_le(staged, 8, (double)y / scale);
    cordic_store_f64_le(staged, 16, (double)z / scale);
    memcpy(output, staged, sizeof(staged));
    return CORDIC_OUTPUT_BYTES;
}

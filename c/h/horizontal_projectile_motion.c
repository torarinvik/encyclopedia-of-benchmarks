#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define GRAVITY 9.80665
#define OUTPUT_BYTES 24

static int64_t round_cents(double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const int exponent = (int)((bits >> 52) & UINT64_C(2047));
    if (exponent == 0) return 0;
    const uint64_t mantissa = (UINT64_C(1) << 52) | (bits & UINT64_C(4503599627370495));
    const uint64_t product = mantissa * UINT64_C(25);
    const int right_shift = 1073 - exponent;
    if (right_shift >= 59) return 0;
    uint64_t rounded = product >> right_shift;
    const uint64_t divisor = UINT64_C(1) << right_shift;
    const uint64_t remainder = product & (divisor - 1);
    const uint64_t halfway = divisor >> 1;
    if (remainder > halfway || (remainder == halfway && (rounded & 1U))) ++rounded;
    return (bits >> 63) ? -(int64_t)rounded : (int64_t)rounded;
}

static void store_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t horizontal_projectile_motion(const int64_t *values, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t velocity_milli = values[0], angle_millidegrees = values[1];
    if (velocity_milli < 0 || velocity_milli > 100000 ||
        angle_millidegrees < 1000 || angle_millidegrees > 90000) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    const double velocity = (double)velocity_milli / 1000.0;
    const double angle = (double)angle_millidegrees / 1000.0;
    const double pi_over_180 = 3.14159265358979323846264338327950288 / 180.0;
    const double distance_raw = velocity * velocity * sin((2.0 * angle) * pi_over_180) / GRAVITY;
    const double angle_sine = sin(angle * pi_over_180);
    const double height_raw = velocity * velocity * angle_sine * angle_sine / (2.0 * GRAVITY);
    const double time_raw = (2.0 * velocity) * angle_sine / GRAVITY;
    const double distance = (double)round_cents(distance_raw) / 100.0;
    const double height = (double)round_cents(height_raw) / 100.0;
    const double flight_time = (double)round_cents(time_raw) / 100.0;
    store_f64_le(output, 0, distance);
    store_f64_le(output, 8, height);
    store_f64_le(output, 16, flight_time);
    return OUTPUT_BYTES;
}

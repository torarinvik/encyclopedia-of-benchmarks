/* Real roots of a quadratic, returned in the source formula order. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define COEFFICIENT_LIMIT INT64_C(1000000)

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t quadratic_roots(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 3) return -1;
    const int64_t ai = values[0], bi = values[1], ci = values[2];
    if (ai == 0 || ai < -COEFFICIENT_LIMIT || ai > COEFFICIENT_LIMIT ||
        bi < -COEFFICIENT_LIMIT || bi > COEFFICIENT_LIMIT ||
        ci < -COEFFICIENT_LIMIT || ci > COEFFICIENT_LIMIT) return -1;

    const double a = (double)ai, b = (double)bi, c = (double)ci;
    const double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return 0;

    if (discriminant == 0.0) {
        if (output == NULL || output_capacity < 8) return -2;
        write_f64_le(output, 0, -b / (2.0 * a));
        return 1;
    }

    if (output == NULL || output_capacity < 16) return -2;
    const double square_root = sqrt(discriminant);
    write_f64_le(output, 0, (-b + square_root) / (2.0 * a));
    write_f64_le(output, 8, (-b - square_root) / (2.0 * a));
    return 2;
}


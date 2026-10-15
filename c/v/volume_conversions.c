#include <stddef.h>
#include <stdint.h>
#include <string.h>

static double unit_factor_to_cubic_meters(int64_t unit)
{
    return unit == 1 ? 0.001 : 1.0;
}

int64_t volume_conversions(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length != 3) return -1;
    const int64_t value = input[0], from_unit = input[1], to_unit = input[2];
    if (value < 0 || value > 1000 || from_unit < 0 || from_unit > 2 ||
        to_unit < 0 || to_unit > 2 || from_unit == to_unit) return -1;
    if (capacity < 8 || output == NULL) return -2;
    const double cubic_meters = (double)value * unit_factor_to_cubic_meters(from_unit);
    const double converted = cubic_meters / unit_factor_to_cubic_meters(to_unit);
    uint64_t bits;
    memcpy(&bits, &converted, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[byte] = (uint8_t)(bits >> (8 * byte));
    return 8;
}

/* Solve one missing quantity in the ideal-plate Casimir force equation. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define REDUCED_PLANCK_CONSTANT 1.054571817e-34
#define SPEED_OF_LIGHT 3.0e8
#define PI_VALUE 3.14159265358979323846

double casimir_effect(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t force_units = values[0];
    const int64_t area_units = values[1];
    const int64_t distance_units = values[2];
    if (force_units < 0 || force_units > 1000000 || area_units < 0 || area_units > 1000000 ||
        distance_units < 0 || distance_units > 1000000) return INVALID_RESULT;
    const int zero_count = (force_units == 0) + (area_units == 0) + (distance_units == 0);
    if (zero_count != 1) return INVALID_RESULT;
    const double force = (double)force_units * 1.0e-12;
    const double area = (double)area_units * 1.0e-6;
    const double distance = (double)distance_units * 1.0e-6;
    if (force_units == 0)
        return (REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0) * area) /
            (240.0 * pow(distance, 4.0));
    if (area_units == 0)
        return (240.0 * force * pow(distance, 4.0)) /
            (REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0));
    return pow((REDUCED_PLANCK_CONSTANT * SPEED_OF_LIGHT * pow(PI_VALUE, 2.0) * area) /
        (240.0 * force), 0.25);
}

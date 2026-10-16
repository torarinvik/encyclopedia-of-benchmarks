/* Selected volume or total surface area of a circular cone. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define INVALID_RESULT (-1.0e300)

double cone(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t radius = values[1];
    const int64_t height = values[2];
    if ((operation != 0 && operation != 1) || radius < 0 || radius > 1000 ||
        height < 0 || height > 1000) return INVALID_RESULT;
    const double radius_squared = (double)radius * (double)radius;
    const double base_area = radius_squared * PI;
    if (operation == 0) return (base_area * (double)height * 1.0) / 3.0;
    return base_area + PI * (double)radius * sqrt(radius_squared + (double)height * (double)height);
}

/* Perimeter and area calculations for a bounded circle radius. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.14159265358979323846

double circle(double radius, double operation)
{
    if (!(isfinite(radius) && isfinite(operation) && radius >= -1000000.0 &&
          radius <= 1000000.0 && (operation == 0.0 || operation == 1.0)))
        return INVALID_RESULT;
    if (operation == 0.0) return radius * 2.0 * PI;
    return pow(radius, 2.0) * PI;
}

/* Compute a regular dodecahedron's area or volume from its edge length. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double dodecahedron(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t edge = values[0];
    const int64_t quantity = values[1];
    if (edge < 1 || edge > 1000000 || (quantity != 0 && quantity != 1)) return INVALID_RESULT;

    const double root_five = sqrt(5.0);
    if (quantity == 0) {
        const double area_factor = 3.0 * sqrt(25.0 + 10.0 * root_five);
        return area_factor * (double)(edge * edge);
    }
    const double volume_factor = (15.0 + 7.0 * root_five) / 4.0;
    return volume_factor * (double)(edge * edge * edge);
}

/* Estimate pi from caller-supplied points in the unit square. */
#include <stddef.h>
#include <stdint.h>

double pi_approximation(const double *points, size_t point_count)
{
    uint64_t inside = 0;
    for (size_t index = 0; index < point_count; ++index) {
        const double x = points[2 * index];
        const double y = points[2 * index + 1];
        if (x * x + y * y <= 1.0) ++inside;
    }
    return 4.0 * (double)inside / (double)point_count;
}

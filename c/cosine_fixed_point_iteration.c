#include <math.h>

double cosine_fixed_point_iteration(double initial, double source_n)
{
    if (!isfinite(initial) || !isfinite(source_n) ||
        initial < 0.0 || initial > 2.0 || source_n < 0.0 || source_n > 64.0 ||
        floor(source_n) != source_n) {
        return -1.0;
    }

    const unsigned updates = (unsigned)source_n + 1u;
    for (unsigned iteration = 0; iteration < updates; ++iteration) {
        initial = 0.5 * (cos(initial) + 2.0);
    }
    return initial;
}

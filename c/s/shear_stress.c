/* Shear stress, force, and area relation over a bounded integer-valued domain. */
#include <math.h>

double shear_stress(double stress, double tangential_force, double area)
{
    if (!isfinite(stress) || !isfinite(tangential_force) || !isfinite(area) ||
        stress < 0.0 || stress > 1000.0 || tangential_force < 0.0 || tangential_force > 1000.0 ||
        area < 0.0 || area > 1000.0 ||
        stress != floor(stress) || tangential_force != floor(tangential_force) || area != floor(area)) return -1.0;
    const int zeros = (stress == 0.0) + (tangential_force == 0.0) + (area == 0.0);
    if (zeros != 1) return -1.0;
    if (stress == 0.0) return tangential_force / area;
    if (tangential_force == 0.0) return stress * area;
    return tangential_force / stress;
}

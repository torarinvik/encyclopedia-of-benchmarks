// Shear stress, force, and area relation over a bounded integer-valued domain.
#include <cmath>

extern "C" double shear_stress(double stress, double tangential_force, double area) noexcept {
    if (!std::isfinite(stress) || !std::isfinite(tangential_force) || !std::isfinite(area) ||
        stress < 0.0 || stress > 1000.0 || tangential_force < 0.0 || tangential_force > 1000.0 ||
        area < 0.0 || area > 1000.0 ||
        stress != std::floor(stress) || tangential_force != std::floor(tangential_force) || area != std::floor(area)) return -1.0;
    const int zeros = (stress == 0.0) + (tangential_force == 0.0) + (area == 0.0);
    if (zeros != 1) return -1.0;
    if (stress == 0.0) return tangential_force / area;
    if (tangential_force == 0.0) return stress * area;
    return tangential_force / stress;
}

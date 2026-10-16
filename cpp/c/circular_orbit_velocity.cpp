#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circular_orbit_velocity(const double *v, std::size_t n, double *out, std::size_t cap) {
    if (v==nullptr || n!=2 || !std::isfinite(v[0]) || !std::isfinite(v[1]) ||
        v[0]<1.0e-12 || v[0]>1.0e25 || v[1]<1.0e-12 || v[1]>1.0e12) return -1;
    if (out==nullptr || cap<1) return -2;
    out[0]=std::sqrt(6.67430e-11*v[0]/v[1]);
    return 1;
}

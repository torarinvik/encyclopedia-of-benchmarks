#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t circular_orbit_velocity(const double *v, size_t n, double *out, size_t cap) {
    if (v==NULL || n!=2 || !isfinite(v[0]) || !isfinite(v[1]) ||
        v[0]<1.0e-12 || v[0]>1.0e25 || v[1]<1.0e-12 || v[1]>1.0e12) return -1;
    if (out==NULL || cap<1) return -2;
    out[0]=sqrt(6.67430e-11*v[0]/v[1]);
    return 1;
}

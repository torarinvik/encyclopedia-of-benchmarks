#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
double pythagoras(const int64_t *v, size_t n) {
    if (!v || n != 6) return INVALID_RESULT;
    for (size_t i=0;i<6;i++) if (v[i] < -1000000 || v[i] > 1000000) return INVALID_RESULT;
    double dx=(double)(v[3]-v[0]),dy=(double)(v[4]-v[1]),dz=(double)(v[5]-v[2]);
    return sqrt(dx*dx+dy*dy+dz*dz);
}

#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t gravitational_force(const double *v, size_t n, double *out, size_t cap) {
    if (v == NULL || n != 6) return -1;
    for (size_t i = 0; i < 6; ++i) if (!isfinite(v[i])) return -1;
    double m1=v[0], x1=v[1], y1=v[2], m2=v[3], x2=v[4], y2=v[5];
    if (fabs(m1)>1.0e12 || fabs(m2)>1.0e12 ||
        (m1!=0.0 && fabs(m1)<1.0e-12) || (m2!=0.0 && fabs(m2)<1.0e-12) ||
        fabs(x1)>1.0e6 || fabs(y1)>1.0e6 || fabs(x2)>1.0e6 || fabs(y2)>1.0e6) return -1;
    double dx=x1-x2, dy=y1-y2, d2=dx*dx+dy*dy;
    if (d2!=0.0 && d2<1.0e-12) return -1;
    if (out==NULL || cap<2) return -2;
    if (d2==0.0) { out[0]=0.0; out[1]=0.0; return 2; }
    double distance=sqrt(d2), magnitude=6.67430e-11*m1*m2/d2;
    out[0]=magnitude*(dx/distance); out[1]=magnitude*(dy/distance);
    return 2;
}

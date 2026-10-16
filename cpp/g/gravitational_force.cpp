#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gravitational_force(const double *v, std::size_t n, double *out, std::size_t cap) {
    if (v==nullptr || n!=6) return -1;
    for (std::size_t i=0;i<6;++i) if (!std::isfinite(v[i])) return -1;
    const double m1=v[0], x1=v[1], y1=v[2], m2=v[3], x2=v[4], y2=v[5];
    if (std::abs(m1)>1.0e12 || std::abs(m2)>1.0e12 || (m1!=0.0 && std::abs(m1)<1.0e-12) ||
        (m2!=0.0 && std::abs(m2)<1.0e-12) || std::abs(x1)>1.0e6 || std::abs(y1)>1.0e6 ||
        std::abs(x2)>1.0e6 || std::abs(y2)>1.0e6) return -1;
    const double dx=x1-x2, dy=y1-y2, d2=dx*dx+dy*dy;
    if (d2!=0.0 && d2<1.0e-12) return -1;
    if (out==nullptr || cap<2) return -2;
    if (d2==0.0) { out[0]=0.0; out[1]=0.0; return 2; }
    const double distance=std::sqrt(d2), magnitude=6.67430e-11*m1*m2/d2;
    out[0]=magnitude*(dx/distance); out[1]=magnitude*(dy/distance);
    return 2;
}

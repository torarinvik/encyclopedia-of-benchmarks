#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1e300;
double derivative(int id, double x, double y) {
    switch (id) { case 0: return y; case 1: return x; case 2: return x+y; case 3: return (x-y)/2.0; default: return 1.0+y*y; }
}
bool rk4_step(int id, double x, double y, double h, double &out) {
    const double k1=derivative(id,x,y);
    const double k2=derivative(id,x+0.5*h,y+0.5*h*k1);
    const double k3=derivative(id,x+0.5*h,y+0.5*h*k2);
    const double k4=derivative(id,x+h,y+h*k3);
    out=y+(1.0/6.0)*h*(k1+2.0*k2+2.0*k3+k4);
    return std::isfinite(k1)&&std::isfinite(k2)&&std::isfinite(k3)&&std::isfinite(k4)&&std::isfinite(out);
}
}

extern "C" double runge_kutta(const std::int64_t *input, std::size_t length) {
    if (!input || length!=5) return invalid_result;
    const auto fid=input[0], y0m=input[1], x0m=input[2], hm=input[3], xem=input[4];
    if (fid<0||fid>4||y0m< -1000000||y0m>1000000||x0m< -1000000||x0m>1000000||
        xem< -1000000||xem>1000000||hm<10000||hm>250000||xem<=x0m) return invalid_result;
    const double y0=static_cast<double>(y0m)/1000000.0, x0=static_cast<double>(x0m)/1000000.0;
    const double h=static_cast<double>(hm)/1000000.0, x_end=static_cast<double>(xem)/1000000.0;
    if (fid==4&&(x0<0.0||y0>0.0)) return invalid_result;
    const double ratio=(x_end-x0)/h;
    const int steps=static_cast<int>(std::ceil(ratio));
    if (steps<1||steps>64) return invalid_result;
    double x=x0,y=y0;
    for(int i=0;i<steps;++i){double next;if(!rk4_step(static_cast<int>(fid),x,y,h,next))return invalid_result;y=next;x+=h;if(!std::isfinite(x))return invalid_result;}
    return y;
}

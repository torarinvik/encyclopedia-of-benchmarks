#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result=-1e300;
double derivative(int id,double x,double y){switch(id){case 0:return y;case 1:return x;case 2:return x+y;case 3:return(x-y)/2.0;default:return 1.0+y*y;}}
bool fehlberg_step(int id,double x,double y,double h,double&out){
    const double k1=h*derivative(id,x,y);
    const double k2=h*derivative(id,x+h/4.0,y+k1/4.0);
    const double k3=h*derivative(id,x+(3.0/8.0)*h,y+(3.0/32.0)*k1+(9.0/32.0)*k2);
    const double k4=h*derivative(id,x+(12.0/13.0)*h,y+(1932.0/2197.0)*k1-(7200.0/2197.0)*k2+(7296.0/2197.0)*k3);
    const double k5=h*derivative(id,x+h,y+(439.0/216.0)*k1-8.0*k2+(3680.0/513.0)*k3-(845.0/4104.0)*k4);
    const double k6=h*derivative(id,x+h/2.0,y-(8.0/27.0)*k1+2.0*k2-(3544.0/2565.0)*k3+(1859.0/4104.0)*k4-(11.0/40.0)*k5);
    out=y+(16.0/135.0)*k1+(6656.0/12825.0)*k3+(28561.0/56430.0)*k4-(9.0/50.0)*k5+(2.0/55.0)*k6;
    return std::isfinite(k1)&&std::isfinite(k2)&&std::isfinite(k3)&&std::isfinite(k4)&&std::isfinite(k5)&&std::isfinite(k6)&&std::isfinite(out);
}
}
extern "C" double runge_kutta_fehlberg_45(const std::int64_t*input,std::size_t length){
    if(!input||length!=5)return invalid_result;const auto fid=input[0],y0m=input[1],x0m=input[2],hm=input[3],xem=input[4];
    if(fid<0||fid>4||y0m< -1000000||y0m>1000000||x0m< -1000000||x0m>1000000||xem< -1000000||xem>1000000||hm<10000||hm>250000||xem<=x0m)return invalid_result;
    const double y0=double(y0m)/1000000.0,x0=double(x0m)/1000000.0,h=double(hm)/1000000.0,x_end=double(xem)/1000000.0;
    if(fid==4&&(x0<0.0||y0>0.0))return invalid_result;const double ratio=(x_end-x0)/h;const int steps=static_cast<int>(ratio);if(steps<1||steps>64)return invalid_result;
    double x=x0,y=y0;for(int i=0;i<steps;++i){double next;if(!fehlberg_step(int(fid),x,y,h,next))return invalid_result;y=next;x=h+x;if(!std::isfinite(x))return invalid_result;}return y;
}

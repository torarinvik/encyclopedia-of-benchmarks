#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result=-1e300;
double derivative(int id,double x,double y){switch(id){case 0:return y;case 1:return x;case 2:return x+y;case 3:return(x-y)/2.0;default:return 1.0+y*y;}}
bool gill_step(int id,double x,double y,double h,double&out){
    const double root2=std::sqrt(2.0),k1=h*derivative(id,x,y),k2=h*derivative(id,x+h/2.0,y+k1/2.0);
    const double k3=h*derivative(id,x+h/2.0,y+(-0.5+1.0/root2)*k1+(1.0-1.0/root2)*k2);
    const double k4=h*derivative(id,x+h,y-(1.0/root2)*k2+(1.0+1.0/root2)*k3);
    out=y+(k1+(2.0-root2)*k2+(2.0+root2)*k3+k4)/6.0;
    return std::isfinite(k1)&&std::isfinite(k2)&&std::isfinite(k3)&&std::isfinite(k4)&&std::isfinite(out);
}
}
extern "C" double runge_kutta_gills(const std::int64_t*input,std::size_t length){
    if(!input||length!=5)return invalid_result;const auto fid=input[0],y0m=input[1],x0m=input[2],hm=input[3],xem=input[4];
    if(fid<0||fid>4||y0m< -1000000||y0m>1000000||x0m< -1000000||x0m>1000000||xem< -1000000||xem>1000000||hm<10000||hm>250000||xem<=x0m)return invalid_result;
    const double y0=double(y0m)/1000000.0,x0=double(x0m)/1000000.0,h=double(hm)/1000000.0,x_end=double(xem)/1000000.0;
    if(fid==4&&(x0<0.0||y0>0.0))return invalid_result;const double ratio=(x_end-x0)/h;const int steps=static_cast<int>(ratio);if(steps<1||steps>64)return invalid_result;
    double x=x0,y=y0;for(int i=0;i<steps;++i){double next;if(!gill_step(int(fid),x,y,h,next))return invalid_result;y=next;x+=h;if(!std::isfinite(x))return invalid_result;}return y;
}

#include <cstddef>
#include <cstdint>
#include <cmath>
extern "C" double extended_kalman_filter(const int64_t *v, size_t n) {
    constexpr double bad=-1.0e300, scale=1000.0;
    if (!v || n<10 || n>17) return bad;
    const int64_t steps=v[0]; if(steps<1 || steps>8 || n!=static_cast<size_t>(9+steps))return bad;
    for(size_t i=1;i<9;i++)if(v[i]<-10000||v[i]>10000)return bad;
    for(size_t i=9;i<n;i++)if(v[i]<-10000||v[i]>10000)return bad;
    double x=v[1]/scale,y=v[2]/scale,p00=v[3]/scale,p01=v[4]/scale,p11=v[5]/scale;
    double q0=v[6]/scale,q1=v[7]/scale,r=v[8]/scale;
    if(v[1]<-2000||v[1]>2000||v[2]<-2000||v[2]>2000||p00<=0||p11<=0||p00*p11<=p01*p01||q0<0||q1<0||r<=0||r>10)return bad;
    for(int64_t t=0;t<steps;t++){
        double f01=.1,f10=.1*x,nx=x+f01*y,ny=y+.05*x*x;
        double a=p00+2*f01*p01+f01*f01*p11+q0;
        double b=f10*p00+(1+f01*f10)*p01+f01*p11;
        double c=f10*f10*p00+2*f10*p01+p11+q1;
        x=nx;y=ny;p00=a;p01=b;p11=c;
        double h0=.1*x,pred=.05*x*x+y,res=v[9+t]/scale-pred;
        double s=h0*h0*p00+2*h0*p01+p11+r;if(!(s>0)||!std::isfinite(s))return bad;
        double k0=(p00*h0+p01)/s,k1=(p01*h0+p11)/s;x+=k0*res;y+=k1*res;
        double a00=1-k0*h0,a01=-k0,a10=-k1*h0,a11=1-k1;
        double z00=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r;
        double z01=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r;
        double z11=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r;
        p00=z00;p01=z01;p11=z11;
    }return x;
}

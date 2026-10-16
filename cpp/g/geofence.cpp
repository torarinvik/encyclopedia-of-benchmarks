#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t geofence(const std::int64_t *a,std::size_t n){
 if(!a||n!=5)return -1;
 if(a[0]<-90000000||a[0]>90000000||a[2]<-90000000||a[2]>90000000||a[1]<-180000000||a[1]>180000000||a[3]<-180000000||a[3]>180000000||a[4]<-1000000||a[4]>30000000000LL)return -1;
 constexpr double pi=3.14159265358979323846264338327950288;const double f=pi/180000000.0;
 const double lat1=static_cast<double>(a[0])*f,lon1=static_cast<double>(a[1])*f,lat2=static_cast<double>(a[2])*f,lon2=static_cast<double>(a[3])*f;
 const double dl=lat2-lat1,dg=lon2-lon1,s1=std::sin(dl/2),s2=std::sin(dg/2);
 double h=s1*s1+std::cos(lat1)*std::cos(lat2)*s2*s2;if(h<0)h=0;if(h>1)h=1;
 const double distance=6371010.0*(2*std::atan2(std::sqrt(h),std::sqrt(1-h)));
 return distance<=static_cast<double>(a[4])/1000.0;
}

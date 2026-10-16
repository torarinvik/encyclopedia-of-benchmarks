#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define PI 3.14159265358979323846264338327950288
int64_t geofence(const int64_t *a,size_t n){
 if(!a||n!=5)return -1;
 if(a[0]<-90000000||a[0]>90000000||a[2]<-90000000||a[2]>90000000||a[1]<-180000000||a[1]>180000000||a[3]<-180000000||a[3]>180000000||a[4]<-1000000||a[4]>30000000000LL)return -1;
 double f=PI/180000000.0,lat1=a[0]*f,lon1=a[1]*f,lat2=a[2]*f,lon2=a[3]*f;
 double dlat=lat2-lat1,dlon=lon2-lon1,s1=sin(dlat/2.0),s2=sin(dlon/2.0);
 double hav=s1*s1+cos(lat1)*cos(lat2)*s2*s2;if(hav<0)hav=0;if(hav>1)hav=1;
 double dist=6371010.0*(2.0*atan2(sqrt(hav),sqrt(1.0-hav)));
 return dist<=((double)a[4]/1000.0);
}

#include <stddef.h>
#include <stdint.h>
#include <math.h>
#define PI 3.14159265358979323846264338327950288
#define INV (-1.0e300)
double lamberts_ellipsoidal_distance(const int64_t*v,size_t n){if(n!=4)return INV;if(v[0]<-90000000||v[0]>90000000||v[2]<-90000000||v[2]>90000000||v[1]<-180000000||v[1]>180000000||v[3]<-180000000||v[3]>180000000)return INV;if(v[0]==v[2]&&v[1]==v[3])return INV;double lat1=v[0]/1e6,lon1=v[1]/1e6,lat2=v[2]/1e6,lon2=v[3]/1e6;double p1=lat1*PI/180.,p2=lat2*PI/180.,l1=lon1*PI/180.,l2=lon2*PI/180.;double h=sqrt(pow(sin((p2-p1)/2),2)+cos(p1)*cos(p2)*pow(sin((l2-l1)/2),2));if(h==0)return INV;double sigma=2*asin(h);double f=(6378137.0-6356752.314245)/6378137.0;double b1=atan((1-f)*tan(lat1*PI/180.)),b2=atan((1-f)*tan(lat2*PI/180.));double p=(b1+b2)/2,q=(b2-b1)/2;double x=(sigma-sin(sigma))*((pow(sin(p),2)*pow(cos(q),2))/pow(cos(sigma/2),2));double y=(sigma+sin(sigma))*((pow(cos(p),2)*pow(sin(q),2))/pow(sin(sigma/2),2));return 6378137.0*(sigma-(f/2)*(x+y));}

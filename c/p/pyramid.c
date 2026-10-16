#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define BAD -1e300
double pyramid(const int64_t*v,size_t n){if(!v||n!=3||v[0]<0||v[0]>1||v[1]<1||v[1]>10000000||v[2]<1||v[2]>10000000)return BAD;double b=(double)v[1]/1000.0,h=(double)v[2]/1000.0,area=pow(b,2);if(v[0]==0)return (area*h)/3.0;return area+((b*4.0)/2.0)*sqrt(pow(b/2.0,2)+pow(h,2));}

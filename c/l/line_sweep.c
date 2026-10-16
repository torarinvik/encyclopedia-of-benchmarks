#include <stddef.h>
#include <stdint.h>
double line_sweep(const int64_t*v,size_t n){if(n<1||n>17)return -1e300;int64_t count=v[0];if(count<0||count>8||n!=(size_t)(1+2*count))return -1e300;if(!count)return 0.0;int line[22]={0};for(int64_t i=0;i<count;i++){int64_t s=v[1+2*i],e=v[2+2*i];if(s<0||e<s||e>20)return -1e300;line[s]++;line[e+1]--;}int c=0,m=0;for(int i=0;i<22;i++){c+=line[i];if(c>m)m=c;}return m>1?1.0:0.0;}

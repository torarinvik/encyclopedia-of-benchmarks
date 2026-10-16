#include <cstddef>
#include <cstdint>
double line_sweep(const std::int64_t*v,std::size_t n){if(n<1||n>17)return -1e300;auto count=v[0];if(count<0||count>8||n!=std::size_t(1+2*count))return -1e300;if(!count)return 0.0;int line[22]={};for(std::int64_t i=0;i<count;i++){auto s=v[1+2*i],e=v[2+2*i];if(s<0||e<s||e>20)return -1e300;line[s]++;line[e+1]--;}int c=0,m=0;for(int d:line){c+=d;if(c>m)m=c;}return m>1?1.0:0.0;}

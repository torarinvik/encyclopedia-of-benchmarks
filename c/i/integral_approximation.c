#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
static double f(int64_t id,double x){return id==0?x*x:x*x*x-x*x+378.0;}
double integral_approximation(const int64_t*v,size_t n){if(!v||n!=4)return INVALID_RESULT;int64_t id=v[0],li=v[1],ui=v[2],di=v[3];if(id<0||id>1||li<0||ui>32||li>=ui||di<1||di>8)return INVALID_RESULT;double lo=(double)li/8.0,hi=(double)ui/8.0,d=(double)di/8.0;uint64_t count=(uint64_t)((hi-lo)/d);if(count>32)return INVALID_RESULT;double total=0;for(uint64_t i=0;i<count;i++){double begin=lo+(double)i*d;double end=lo+(double)(i+1)*d;total+=d*(f(id,begin)+f(id,end))/2.0;}return total;}

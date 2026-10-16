#include <cstddef>
#include <cstdint>
static double f(int64_t id,double x){return id==0?x*x:x*x*x-x*x+378.0;}
extern "C" double integral_approximation(const int64_t*v,size_t n){if(!v||n!=4)return -1.0e300;auto id=v[0],li=v[1],ui=v[2],di=v[3];if(id<0||id>1||li<0||ui>32||li>=ui||di<1||di>8)return -1.0e300;double lo=double(li)/8.0,hi=double(ui)/8.0,d=double(di)/8.0;auto count=uint64_t((hi-lo)/d);if(count>32)return -1.0e300;double total=0;for(uint64_t i=0;i<count;i++){double begin=lo+double(i)*d,end=lo+double(i+1)*d;total+=d*(f(id,begin)+f(id,end))/2.0;}return total;}

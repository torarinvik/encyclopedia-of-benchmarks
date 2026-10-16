#include <cstddef>
#include <cstdint>
static std::int64_t peak(const std::int64_t*a,std::int64_t lo,std::int64_t hi,std::int64_t n){auto mid=lo+(hi-lo)/2;if((mid==0||a[mid-1]<=a[mid])&&(mid==n-1||a[mid+1]<=a[mid]))return mid;if(mid>0&&a[mid-1]>a[mid])return peak(a,lo,mid-1,n);return peak(a,mid+1,hi,n);}
extern "C" std::int64_t peak_element(const std::int64_t*v,std::size_t n)noexcept{if(!v||n<2||n>129||v[0]<1||v[0]>128||n!=static_cast<std::size_t>(v[0])+1)return -1;auto count=v[0];for(std::int64_t i=0;i<count;i++)if(v[i+1]<-2147483648LL||v[i+1]>2147483647LL)return -1;return peak(v+1,0,count-1,count);}

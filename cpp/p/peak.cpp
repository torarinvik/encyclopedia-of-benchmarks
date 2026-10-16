#include <cstddef>
#include <cstdint>
static std::int64_t find_peak(const std::int64_t*a,std::size_t lo,std::size_t hi){auto n=hi-lo,m=n/2;auto l=a[lo+m-1],c=a[lo+m],r=a[lo+m+1];if(c>l&&c>r)return c;if(l<r){auto start=m;if(m==2)--start;return find_peak(a,lo+start,hi);}auto end=m;if(m==2)++end;return find_peak(a,lo,lo+end);}
extern "C" std::int64_t peak(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<4||n>65||v[0]<3||v[0]>64||n!=std::size_t(v[0])+1)return -1;auto len=std::size_t(v[0]),p=std::size_t(1);for(std::size_t i=0;i<len;i++)if(v[i+1]<-1000000||v[i+1]>1000000)return -1;while(p<len-1&&v[p+1]>v[p])++p;if(p==1||p>=len-1)return -1;for(std::size_t i=p;i+1<len;i++)if(v[i+1]>=v[i])return -1;return find_peak(v+1,0,len);}

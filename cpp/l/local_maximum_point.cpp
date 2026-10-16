#include <cstddef>
#include <cstdint>
extern "C" std::int64_t local_maximum_point(const std::int64_t*v,std::size_t n){if(!v||n<1||n>64)return -1;for(std::size_t i=0;i<n;i++)if(v[i]<-1000000||v[i]>1000000)return -1;std::size_t s=0,e=n-1;for(;;){auto m=s+(e-s)/2;if((m==0||v[m-1]<=v[m])&&(m==n-1||v[m+1]<=v[m]))return m;if(m>0&&v[m-1]>v[m])e=m-1;else s=m+1;}}

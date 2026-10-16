#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_COUNT=6;
static std::uint32_t mix(std::uint32_t h,std::uint8_t b){return (h^b)*16777619u;}
static bool next_perm(std::int32_t*a,std::size_t n){std::size_t i=n-1;while(i>0&&a[i-1]>=a[i])--i;if(i==0)return false;std::size_t j=n-1;while(a[j]<=a[i-1])--j;auto t=a[i-1];a[i-1]=a[j];a[j]=t;for(std::size_t l=i,r=n-1;l<r;++l,--r){t=a[l];a[l]=a[r];a[r]=t;}return true;}
extern "C" std::int64_t permutations(const std::int64_t*v,std::size_t n) noexcept{if(!v||n<2||n>7||v[0]<1||v[0]>6||n!=std::size_t(v[0])+1)return -1;std::size_t count=std::size_t(v[0]);std::int32_t a[6];for(std::size_t i=0;i<count;i++){if(v[i+1]<INT32_MIN||v[i+1]>INT32_MAX)return -1;a[i]=std::int32_t(v[i+1]);if(i>0&&a[i-1]>=a[i])return -1;}std::uint32_t h=2166136261u;do{for(std::size_t i=0;i<count;i++){auto u=std::uint32_t(a[i]);for(unsigned b=0;b<4;b++)h=mix(h,std::uint8_t(u>>(8*b)));}h=mix(h,255);}while(next_perm(a,count));return h;}

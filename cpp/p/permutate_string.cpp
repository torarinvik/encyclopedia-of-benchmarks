#include <cstddef>
#include <cstdint>
static void sort_bytes(std::uint8_t*a,std::size_t n){for(std::size_t i=1;i<n;i++){auto x=a[i];auto j=i;while(j>0&&a[j-1]>x){a[j]=a[j-1];--j;}a[j]=x;}}
static bool next_perm(std::uint8_t*a,std::size_t n){std::size_t i=n-1;while(i>0&&a[i-1]>=a[i])--i;if(i==0)return false;std::size_t j=n-1;while(a[j]<=a[i-1])--j;auto t=a[i-1];a[i-1]=a[j];a[j]=t;for(std::size_t l=i,r=n-1;l<r;++l,--r){t=a[l];a[l]=a[r];a[r]=t;}return true;}
static std::uint32_t mix(std::uint32_t h,std::uint8_t b){return (h^b)*16777619u;}
extern "C" std::int64_t permutate_string(const std::int64_t*v,std::size_t n) noexcept{if(!v||n<2||n>8||v[0]<1||v[0]>7||n!=std::size_t(v[0])+1)return -1;std::size_t len=std::size_t(v[0]);std::uint8_t a[7];for(std::size_t i=0;i<len;i++){if(v[i+1]<33||v[i+1]>126)return -1;a[i]=std::uint8_t(v[i+1]);for(std::size_t j=0;j<i;j++)if(a[j]==a[i])return -1;}sort_bytes(a,len);std::uint32_t h=2166136261u;do{for(std::size_t i=0;i<len;i++)h=mix(h,a[i]);h=mix(h,0);}while(next_perm(a,len));return h;}

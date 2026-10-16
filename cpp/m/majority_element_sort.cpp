#include <cstddef>
#include <cstdint>
extern "C" std::int64_t majority_element_sort(const std::int64_t*v,std::size_t n) noexcept{if(!v||n<2||n>128)return -1;std::int32_t a[128];for(std::size_t i=0;i<n;i++){if(v[i]<INT32_MIN||v[i]>INT32_MAX)return -1;a[i]=static_cast<std::int32_t>(v[i]);}for(std::size_t i=1;i<n;i++){auto x=a[i];auto j=i;while(j&&a[j-1]>x){a[j]=a[j-1];--j;}a[j]=x;}std::size_t run=1;for(std::size_t i=1;i<n;i++){run=a[i]==a[i-1]?run+1:1;if(run>n/2)return a[i];}return -1;}

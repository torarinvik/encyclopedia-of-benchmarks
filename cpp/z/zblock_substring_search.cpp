#include <cstddef>
#include <cstdint>
#include <array>
#include <algorithm>
extern "C" std::int64_t zblock_substring_search(const std::int64_t*a,std::size_t length){if(!a||length<3)return -1;auto tn=a[0],pn=a[1];if(tn<0||tn>256||pn<1||pn>64||length!=std::size_t(tn+pn+2))return -1;for(std::size_t i=2;i<length;i++)if(a[i]<0||a[i]>127||a[i]==36)return -1;std::size_t n=std::size_t(tn+pn+1),sep=std::size_t(pn);std::array<std::int64_t,321>s{};std::array<std::size_t,321>z{};for(std::size_t i=0;i<sep;i++)s[i]=a[2+tn+i];s[sep]=-1;for(std::size_t i=0;i<std::size_t(tn);i++)s[sep+1+i]=a[2+i];std::size_t l=0,r=0;for(std::size_t i=1;i<n;i++){z[i]=i<=r?std::min(r-i+1,z[i-l]):0;while(i+z[i]<n&&s[z[i]]==s[i+z[i]])++z[i];if(i+z[i]>0&&i+z[i]-1>r){l=i;r=i+z[i]-1;}}std::int64_t found=0;for(std::size_t i=sep+1;i<n;i++)if(z[i]>=sep)++found;return found;}

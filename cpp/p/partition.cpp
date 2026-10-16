#include <cstddef>
#include <cstdint>
static bool solve(const std::int64_t*v,std::size_t n,std::size_t i,std::int64_t target,std::int64_t half){if(target==half)return true;if(i>=n||target>half)return false;return solve(v,n,i+1,target+v[i],half)||solve(v,n,i+1,target,half);}
extern "C" std::int64_t partition(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<1||n>17||v[0]<0||v[0]>16||n!=std::size_t(v[0])+1)return -1;auto count=std::size_t(v[0]);std::int64_t sum=0;for(std::size_t i=1;i<n;i++){if(v[i]<0||v[i]>1000)return -1;sum+=v[i];}if(sum%2)return 0;return solve(v+1,count,0,0,sum/2); }

#include <cstdint>
#include <cstring>
static constexpr int MAX_N=100, STRIDE=101;
static std::int64_t count_parts(int n,int k,std::int64_t memo[STRIDE*STRIDE]){if((n==0&&k==0)||(n>0&&k==1)||n==k)return 1;if(k==0||k>n)return 0;int i=n*STRIDE+k;if(memo[i]>=0)return memo[i];return memo[i]=count_parts(n-1,k-1,memo)+count_parts(n-k,k,memo);}
extern "C" std::int64_t partitions(std::int64_t n) noexcept{if(n<0||n>MAX_N)return INT64_MIN;std::int64_t memo[STRIDE*STRIDE];std::memset(memo,0xff,sizeof memo);std::int64_t total=0;for(int k=1;k<=n;k++)total+=count_parts((int)n,k,memo);return n==0?1:total;}

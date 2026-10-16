#include <cstddef>
#include <cstdint>
extern "C" std::int64_t longest_repeated_substring(const std::int64_t*p,std::size_t n) noexcept {if(!p||n<1||n>128||p[0]<0||p[0]>127||n!=static_cast<std::size_t>(p[0]+1))return -1;auto z=p[0];for(std::int64_t i=0;i<z;i++)if(p[i+1]<0||p[i+1]>127)return -1;std::int64_t dp[128][128]{};std::int64_t best=0;for(std::int64_t i=z-1;i>=0;i--)for(std::int64_t j=z-1;j>i;j--)if(p[i+1]==p[j+1]){dp[i][j]=1+dp[i+1][j+1];if(dp[i][j]>best)best=dp[i][j];}return best;}

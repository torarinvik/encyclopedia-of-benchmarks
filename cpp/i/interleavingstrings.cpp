#include <cstddef>
#include <cstdint>
#include <array>
extern "C" std::int64_t interleavingstrings(const std::int64_t*a,std::size_t n){if(!a||n<3)return -1;auto m=a[0],k=a[1],q=a[2];if(m<0||m>32||k<0||k>32||q!=m+k||n!=std::size_t(3+m+k+q))return -1;for(std::size_t i=3;i<n;i++)if(a[i]<0||a[i]>127)return -1;auto s2=3+std::size_t(m),s3=s2+std::size_t(k);std::array<std::array<bool,33>,33>dp{};dp[0][0]=true;for(std::size_t i=0;i<=std::size_t(m);i++)for(std::size_t j=0;j<=std::size_t(k);j++){if(i&&dp[i-1][j]&&a[3+i-1]==a[s3+i+j-1])dp[i][j]=true;if(j&&dp[i][j-1]&&a[s2+j-1]==a[s3+i+j-1])dp[i][j]=true;}return dp[std::size_t(m)][std::size_t(k)]?1:0;}

#include <stddef.h>
#include <stdint.h>
int64_t interleavingstrings(const int64_t*a,size_t n){if(!a||n<3)return -1;int64_t m=a[0],k=a[1],q=a[2];if(m<0||m>32||k<0||k>32||q!=m+k||n!=(size_t)(3+m+k+q))return -1;for(size_t i=3;i<n;i++)if(a[i]<0||a[i]>127)return -1;size_t s2=3+(size_t)m,s3=s2+(size_t)k;uint8_t dp[33][33]={0};dp[0][0]=1;for(size_t i=0;i<=m;i++)for(size_t j=0;j<=k;j++){if(i&&dp[i-1][j]&&a[3+i-1]==a[s3+i+j-1])dp[i][j]=1;if(j&&dp[i][j-1]&&a[s2+j-1]==a[s3+i+j-1])dp[i][j]=1;}return dp[m][k]?1:0;}

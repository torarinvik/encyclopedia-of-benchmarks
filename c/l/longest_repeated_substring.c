#include <stddef.h>
#include <stdint.h>
int64_t longest_repeated_substring(const int64_t*p,size_t n){if(!p||n<1||n>128||p[0]<0||p[0]>127||n!=(size_t)(p[0]+1))return -1;int64_t z=p[0];for(int64_t i=0;i<z;i++)if(p[i+1]<0||p[i+1]>127)return -1;int64_t dp[128][128]={{0}},best=0;for(int64_t i=z-1;i>=0;i--)for(int64_t j=z-1;j>i;j--)if(p[i+1]==p[j+1]){dp[i][j]=1+dp[i+1][j+1];if(dp[i][j]>best)best=dp[i][j];}return best;}

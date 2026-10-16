#include <stddef.h>
#include <stdint.h>
int64_t longest_repeating_subsequence(const int64_t *p, size_t n) {
 if (!p || n < 1 || n > 256 || p[0] < 0 || p[0] > 255 || n != (size_t)(p[0]+1)) return -1;
 int64_t size=p[0]; for (int64_t i=0;i<size;i++) if(p[1+i]<0||p[1+i]>127)return -1;
 int64_t dp[256]={0};
 for(int64_t i=1;i<=size;i++){int64_t diag=0;for(int64_t j=1;j<=size;j++){int64_t above=dp[j]; if(p[i]==p[j]&&i!=j)dp[j]=diag+1;else if(dp[j-1]>dp[j])dp[j]=dp[j-1];diag=above;}} return dp[size];
}

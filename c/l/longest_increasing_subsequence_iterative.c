#include <stddef.h>
#include <stdint.h>
int64_t longest_increasing_subsequence_iterative(const int64_t*v,size_t n){if(!v||n<1||n>65)return -1;int64_t count=v[0];if(count<0||count>64||n!=(size_t)count+1)return -1;int64_t a[64],dp[64];for(size_t i=0;i<(size_t)count;i++){a[i]=v[i+1];if(a[i]<-1000000||a[i]>1000000)return -1;dp[i]=1;}for(size_t i=0;i<(size_t)count;i++)for(size_t j=0;j<i;j++)if(a[j]<=a[i]&&dp[j]+1>dp[i])dp[i]=dp[j]+1;int64_t best=0;for(size_t i=0;i<(size_t)count;i++)if(dp[i]>best)best=dp[i];return best;}

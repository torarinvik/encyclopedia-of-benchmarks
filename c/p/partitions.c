#include <stddef.h>
#include <stdint.h>
#include <string.h>
#define MAX_N 100
#define STRIDE 101
static int64_t count_parts(int n,int k,int64_t memo[STRIDE*STRIDE]){
 if((n==0&&k==0)||(n>0&&k==1)||n==k)return 1;
 if(k==0||k>n)return 0;
 size_t i=(size_t)n*STRIDE+(size_t)k;
 if(memo[i]>=0)return memo[i];
 memo[i]=count_parts(n-1,k-1,memo)+count_parts(n-k,k,memo);
 return memo[i];
}
int64_t partitions(int64_t n){if(n<0||n>MAX_N)return INT64_MIN;int64_t memo[STRIDE*STRIDE];memset(memo,0xff,sizeof memo);int64_t total=0;for(int k=1;k<=n;k++)total+=count_parts((int)n,k,memo);return n==0?1:total;}

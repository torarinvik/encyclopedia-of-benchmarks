#include <stddef.h>
#include <stdint.h>
#define LIM 16
int64_t maximal_square(const int64_t *a,size_t len){if(!a||len<3||len>258||a[0]<1||a[0]>LIM||a[1]<1||a[1]>LIM||(size_t)a[0]*(size_t)a[1]+2!=len)return -1;size_t rows=(size_t)a[0],cols=(size_t)a[1];int64_t dp[LIM]={0};for(size_t i=0;i<rows*cols;i++)if(a[i+2]!=0&&a[i+2]!=1)return -1;size_t best=0;for(size_t r=0;r<rows;r++){size_t diag=0;for(size_t c=0;c<cols;c++){size_t above=(size_t)dp[c],idx=r*cols+c;if(a[idx+2]==1){if(r==0||c==0)dp[c]=1;else{size_t m=diag;if((size_t)dp[c]<m)m=(size_t)dp[c];if((size_t)dp[c-1]<m)m=(size_t)dp[c-1];dp[c]=(int64_t)(m+1);}if((size_t)dp[c]>best)best=(size_t)dp[c];}else dp[c]=0;diag=above;}}return (int64_t)(best*best);}

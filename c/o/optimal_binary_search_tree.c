#include <stddef.h>
#include <stdint.h>
int64_t optimal_binary_search_tree(const int64_t*v,size_t n){if(!v||n<2||n>33||v[0]<1||v[0]>32||n!=(size_t)v[0]+1)return -1;size_t k=(size_t)v[0];int64_t f[32],prefix[33]={0},dp[32][32]={0};for(size_t i=0;i<k;i++){f[i]=v[i+1];if(f[i]<0||f[i]>1000)return -1;prefix[i+1]=prefix[i]+f[i];dp[i][i]=f[i];}for(size_t w=2;w<=k;w++)for(size_t s=0;s+w<=k;s++){size_t e=s+w-1;int64_t best=INT64_MAX,total=prefix[e+1]-prefix[s];for(size_t r=s;r<=e;r++){int64_t cost=total+(r>s?dp[s][r-1]:0)+(r<e?dp[r+1][e]:0);if(cost<best)best=cost;}dp[s][e]=best;}return dp[0][k-1];}

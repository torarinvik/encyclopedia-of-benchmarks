#include <stddef.h>
#include <stdint.h>
int64_t ones_and_zeros(const int64_t*v,size_t n){if(!v||n<3||v[0]<0||v[0]>32||v[1]<0||v[1]>32||v[2]<0||v[2]>32||n!=3+2*(size_t)v[0])return -1;int64_t dp[33][33]={0};for(size_t i=0;i<(size_t)v[0];i++){int64_t z=v[3+2*i],o=v[4+2*i];if(z<0||z>32||o<0||o>32)return -1;for(int64_t a=v[1];a>=z;a--)for(int64_t b=v[2];b>=o;b--){int64_t cand=dp[a-z][b-o]+1;if(cand>dp[a][b])dp[a][b]=cand;}}return dp[v[1]][v[2]];}

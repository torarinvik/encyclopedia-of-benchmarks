#include <stddef.h>
#include <stdint.h>
static int solve(const int64_t*v,size_t n,size_t i,int64_t target,int64_t half){if(target==half)return 1;if(i>=n||target>half)return 0;return solve(v,n,i+1,target+v[i],half)||solve(v,n,i+1,target,half);}
int64_t partition(const int64_t*v,size_t n){if(!v||n<1||n>17||v[0]<0||v[0]>16||n!=(size_t)v[0]+1)return -1;size_t count=(size_t)v[0];int64_t sum=0;for(size_t i=1;i<n;i++){if(v[i]<0||v[i]>1000)return -1;sum+=v[i];}if(sum%2)return 0;return solve(v+1,count,0,0,sum/2);}

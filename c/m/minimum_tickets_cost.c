#include <stddef.h>
#include <stdint.h>
int64_t minimum_tickets_cost(const int64_t*v,size_t n){if(!v||n<4||n>369||v[0]<0||v[0]>365)return -1;size_t d=(size_t)v[0];if(n!=d+4)return -1;int travel[366]={0};for(size_t i=0;i<d;i++){int64_t x=v[i+1];if(x<1||x>365||travel[x])return -1;travel[x]=1;}int64_t c[3];for(int i=0;i<3;i++){c[i]=v[d+1+i];if(c[i]<0||c[i]>1000000)return -1;}int64_t dp[397]={0};for(int day=365;day>=1;day--){dp[day]=dp[day+1];if(travel[day]){int64_t a=c[0]+dp[day+1],b=c[1]+dp[day+7],z=c[2]+dp[day+30];dp[day]=a<b?a:b; if(z<dp[day])dp[day]=z;}}return dp[1];}

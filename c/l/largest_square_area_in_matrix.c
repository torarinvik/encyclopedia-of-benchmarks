#include <stddef.h>
#include <stdint.h>
int64_t largest_square_area_in_matrix(const int64_t*v,size_t n){if(!v||n<2||n>66)return -2;int64_t r=v[0],c=v[1];if(r<1||r>8||c<1||c>8||n!=2+(size_t)(r*c))return -2;int64_t a[64],dp[9][9]={0},best=0;for(int64_t i=0;i<r*c;i++){a[i]=v[2+i];if(a[i]!=0&&a[i]!=1)return -2;}for(int64_t i=r-1;i>=0;i--)for(int64_t j=c-1;j>=0;j--){if(a[i*c+j]){int64_t x=dp[i+1][j],y=dp[i][j+1],z=dp[i+1][j+1],m=x<y?x:y;if(z<m)m=z;dp[i][j]=1+m;if(dp[i][j]>best)best=dp[i][j];}}return best;}

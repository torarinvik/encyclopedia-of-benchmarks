#include <stdint.h>
#define MAX_ROW 30
#define MOD 1000000007LL
int64_t pascal_triangle_ii(int64_t row){if(row<0||row>MAX_ROW)return INT64_MIN;int64_t triangle[31][31]={0};triangle[0][0]=1;for(int64_t i=1;i<=row;i++){triangle[i][0]=triangle[i][i]=1;for(int64_t j=1;j<i;j++)triangle[i][j]=triangle[i-1][j-1]+triangle[i-1][j];}int64_t hash=0;for(int64_t j=0;j<=row;j++)hash=(hash*31+triangle[row][j])%MOD;return hash;}

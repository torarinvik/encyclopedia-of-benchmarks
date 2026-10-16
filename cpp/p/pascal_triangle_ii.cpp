#include <cstdint>
static constexpr std::int64_t MAX_ROW=30, MOD=1000000007;
extern "C" std::int64_t pascal_triangle_ii(std::int64_t row) noexcept{if(row<0||row>MAX_ROW)return INT64_MIN;std::int64_t triangle[31][31]{};triangle[0][0]=1;for(std::int64_t i=1;i<=row;i++){triangle[i][0]=triangle[i][i]=1;for(std::int64_t j=1;j<i;j++)triangle[i][j]=triangle[i-1][j-1]+triangle[i-1][j];}std::int64_t hash=0;for(std::int64_t j=0;j<=row;j++)hash=(hash*31+triangle[row][j])%MOD;return hash;}

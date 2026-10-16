#include <cstddef>
#include <cstdint>
#include <algorithm>
extern "C" std::int64_t needleman_wunsch(const std::int64_t *v,std::size_t n){
 constexpr std::int64_t invalid=INT64_MIN;constexpr std::size_t max_len=128;
 if(!v||n<5||n>261)return invalid;auto a=v[0],b=v[1],match=v[2],mismatch=v[3],gap=v[4];
 if(a<0||a>128||b<0||b>128||match<0||match>10||mismatch< -10||mismatch>0||gap< -10||gap>0||n!=5+static_cast<std::size_t>(a+b))return invalid;
 for(std::size_t i=0;i<static_cast<std::size_t>(a+b);++i)if(v[5+i]<65||v[5+i]>90)return invalid;
 std::int64_t dp[max_len+1]{};for(std::size_t j=0;j<=static_cast<std::size_t>(b);++j)dp[j]=static_cast<std::int64_t>(j)*gap;
 for(std::size_t i=1;i<=static_cast<std::size_t>(a);++i){auto diagonal=dp[0];dp[0]=static_cast<std::int64_t>(i)*gap;for(std::size_t j=1;j<=static_cast<std::size_t>(b);++j){auto old=dp[j];auto score=v[5+i-1]==v[5+static_cast<std::size_t>(a)+j-1]?match:mismatch;dp[j]=std::max({diagonal+score,old+gap,dp[j-1]+gap});diagonal=old;}}return dp[static_cast<std::size_t>(b)];
}

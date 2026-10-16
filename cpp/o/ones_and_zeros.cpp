#include <cstddef>
#include <cstdint>
extern "C" std::int64_t ones_and_zeros(const std::int64_t*v,std::size_t n){if(!v||n<3||v[0]<0||v[0]>32||v[1]<0||v[1]>32||v[2]<0||v[2]>32||n!=3+2*static_cast<std::size_t>(v[0]))return -1;std::int64_t dp[33][33]={};for(std::size_t i=0;i<static_cast<std::size_t>(v[0]);i++){auto z=v[3+2*i],o=v[4+2*i];if(z<0||z>32||o<0||o>32)return -1;for(auto a=v[1];a>=z;a--)for(auto b=v[2];b>=o;b--){auto candidate=dp[a-z][b-o]+1;if(candidate>dp[a][b])dp[a][b]=candidate;}}return dp[v[1]][v[2]];}

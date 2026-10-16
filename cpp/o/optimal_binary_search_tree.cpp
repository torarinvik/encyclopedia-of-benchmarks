#include <cstddef>
#include <cstdint>
#include <limits>
extern "C" std::int64_t optimal_binary_search_tree(const std::int64_t*v,std::size_t n){if(!v||n<2||n>33||v[0]<1||v[0]>32||n!=static_cast<std::size_t>(v[0])+1)return -1;auto k=static_cast<std::size_t>(v[0]);std::int64_t prefix[33]={},dp[32][32]={};for(std::size_t i=0;i<k;i++){auto f=v[i+1];if(f<0||f>1000)return -1;prefix[i+1]=prefix[i]+f;dp[i][i]=f;}for(std::size_t w=2;w<=k;w++)for(std::size_t s=0;s+w<=k;s++){auto e=s+w-1;auto best=std::numeric_limits<std::int64_t>::max();auto total=prefix[e+1]-prefix[s];for(std::size_t r=s;r<=e;r++){auto cost=total+(r>s?dp[s][r-1]:0)+(r<e?dp[r+1][e]:0);if(cost<best)best=cost;}dp[s][e]=best;}return dp[0][k-1];}

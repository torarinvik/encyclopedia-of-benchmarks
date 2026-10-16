#include <cstddef>
#include <cstdint>
#include <array>
namespace { constexpr std::size_t NMAX=256; void store(std::int64_t x,std::uint8_t*o,std::size_t p){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;b++)o[p+b]=static_cast<std::uint8_t>(u>>(8*b));} }
extern "C" std::int64_t maximum_minimum_window(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(!input||length<2)return -2;auto n0=input[0];if(n0<1||n0>256||length!=static_cast<std::size_t>(n0)+1)return -2;auto n=static_cast<std::size_t>(n0);
 for(std::size_t i=0;i<n;i++)if(input[i+1]<0||input[i+1]>1000000)return -2;if(!output||capacity<n*8)return -3;
 std::array<std::size_t,NMAX> st{};std::size_t top=0;std::array<int,NMAX> left{},right{};std::array<std::int64_t,NMAX+1> ans{};
 for(std::size_t i=0;i<n;i++){while(top&&input[st[top-1]+1]>=input[i+1])--top;left[i]=top?static_cast<int>(st[top-1]):-1;st[top++]=i;}
 top=0;for(std::size_t ii=n;ii>0;--ii){auto i=ii-1;while(top&&input[st[top-1]+1]>=input[i+1])--top;right[i]=top?static_cast<int>(st[top-1]):static_cast<int>(n);st[top++]=i;}
 for(std::size_t i=0;i<n;i++){auto len=static_cast<std::size_t>(right[i]-left[i]-1);if(input[i+1]>ans[len])ans[len]=input[i+1];}
 for(std::size_t i=n;i>1;--i)if(ans[i-1]<ans[i])ans[i-1]=ans[i];for(std::size_t i=1;i<=n;i++)store(ans[i],output,(i-1)*8);return static_cast<std::int64_t>(n);
}

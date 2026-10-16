#include <cstddef>
#include <cstdint>
extern "C" std::int64_t parenthesis(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=std::size_t(v[0])+1)return -1;std::int64_t balance=0;for(std::size_t i=1;i<n;i++){if(v[i]<0||v[i]>127)return -1;if(v[i]=='(')++balance;else if(v[i]==')'&&--balance<0)return 0;}return balance==0;}

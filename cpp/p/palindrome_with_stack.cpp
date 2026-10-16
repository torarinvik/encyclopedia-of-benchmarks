#include <cstddef>
#include <cstdint>
extern "C" std::int64_t palindrome_with_stack(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=std::size_t(v[0])+1)return -1;unsigned char stack[128];auto len=std::size_t(v[0]);for(std::size_t i=0;i<len;i++){if(v[i+1]<0||v[i+1]>127)return -1;auto c=static_cast<unsigned char>(v[i+1]);if(c>='A'&&c<='Z')c+=32;stack[i]=c;}for(std::size_t i=0;i<len;i++)if(stack[i]!=stack[len-1-i])return 0;return 1;}

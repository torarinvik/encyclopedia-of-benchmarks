#include <cstddef>
#include <cstdint>
extern "C" std::int64_t remove_stars(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap) noexcept {
 if(!v||n<1||n>4097||v[0]<0||v[0]>4096||n!=1+static_cast<std::size_t>(v[0]))return -1;
 std::size_t result=0;for(std::size_t i=0;i<static_cast<std::size_t>(v[0]);++i){auto c=v[i+1];if(c<0||c>127)return -1;if(c=='*'){if(result) --result;}else ++result;}
 if(result>cap||(result&& !out))return -2;std::size_t w=0;for(std::size_t i=0;i<static_cast<std::size_t>(v[0]);++i){auto c=static_cast<std::uint8_t>(v[i+1]);if(c=='*'){if(w)--w;}else out[w++]=c;}return static_cast<std::int64_t>(w);
}

#include <cstddef>
#include <cstdint>
#define MAX_INPUT 322
extern "C" std::int64_t simple_keyword_cypher_encipher(const std::int64_t *v, std::size_t n, std::uint8_t *out, std::size_t cap) {
 if (!v || n < 2 || n > 323) return -1;
 std::int64_t kl=v[0], ml=v[1]; if(kl<0||kl>64||ml<0||ml>256||n!=2+(std::size_t)kl+(std::size_t)ml)return -1;
 std::uint8_t key[26], map[26], result[256]; std::size_t count=0;
 for(std::size_t i=0;i<(std::size_t)kl;i++){std::int64_t x=v[2+i]; if(!((x>=65&&x<=90)||(x>=97&&x<=122)))return -1; if(x>=97)x-=32; std::size_t j=0;while(j<count&&key[j]!=(std::uint8_t)x)j++;if(j==count)key[count++]=(std::uint8_t)x;}
 std::size_t k=0;for(std::size_t i=0;i<count;i++)map[k++]=key[i];for(int x=65;x<=90;x++){std::size_t j=0;while(j<count&&key[j]!=(std::uint8_t)x)j++;if(j==count)map[k++]=(std::uint8_t)x;}
 for(std::size_t i=0;i<(std::size_t)ml;i++){std::int64_t x=v[2+(std::size_t)kl+i];if(x<0||x>127)return -1;if(x>=97&&x<=122)x-=32;if(x>=65&&x<=90){result[i]=map[(std::size_t)(x-65)];}else result[i]=(std::uint8_t)x;}
 if(!out||cap<(std::size_t)ml)return -2;for(std::size_t i=0;i<(std::size_t)ml;i++)out[i]=result[i];return ml;
}

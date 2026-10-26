#include <cstddef>
#include <cstdint>
namespace{void put(std::uint8_t*out,std::size_t p,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b)out[p+b]=std::uint8_t(u>>(8*b));}}
extern "C" std::int64_t deterministic_line_search(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len!=1)return -1;auto target=in[0];if(target==0||target< -50000||target>50000)return -1;
 auto distance=target<0?-target:target;std::int64_t traveled=0,leg=0,depth=1;
 for(;;){bool negative=(leg%2)==0;if((target<0)==negative&&distance<=depth){traveled+=distance;break;}traveled+=2*depth;depth*=2;++leg;}
 if(cap<16||!out)return -2;put(out,0,traveled);put(out,8,leg);return 16;
}

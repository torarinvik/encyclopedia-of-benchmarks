#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 16, B = 6;
constexpr std::size_t IN = 116, OUT = 128;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) { auto bits=static_cast<std::uint64_t>(value); for(std::size_t i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(bits&255u);bits>>=8;} }
}

extern "C" std::int64_t p2p_chord_finger_lookup(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity) {
    if(!input||length<4||length>IN||input[0]<1||input[0]>B||input[1]<2||input[1]>N)return -1;
    int bits=static_cast<int>(input[0]),n=static_cast<int>(input[1]),ring=1<<bits;
    if(n>ring||input[2]<0||input[2]>=n||input[3]<0||input[3]>=ring||length!=static_cast<std::size_t>(4+n+n*bits))return -1;
    std::array<int,N> ids{};std::array<int,N*B> fingers{};
    for(int i=0;i<n;++i){auto raw=input[4+i];if(raw<0||raw>=ring||(i>0&&raw<=ids[i-1]))return -1;ids[i]=static_cast<int>(raw);}
    for(int u=0;u<n;++u)for(int level=0;level<bits;++level){int target=(ids[u]+(1<<level))%ring,successor=0;while(successor<n&&ids[successor]<target)++successor;if(successor==n)successor=0;auto raw=input[4+n+u*bits+level];if(raw<0||raw>=n||raw!=successor)return -1;fingers[u*bits+level]=successor;}
    int owner=0;while(owner<n&&ids[owner]<input[3])++owner;if(owner==n)owner=0;
    std::array<int,N> route{};int route_len=1,current=static_cast<int>(input[2]);route[0]=current;
    for(int step=0;step<n&&current!=owner;++step){int distance=(ids[owner]-ids[current]+ring)%ring,chosen=-1;for(int level=bits-1;level>=0;--level){int candidate=fingers[current*bits+level],progress=(ids[candidate]-ids[current]+ring)%ring;if(progress>0&&progress<=distance){chosen=candidate;break;}}if(chosen<0||route_len>=n)return -1;for(int j=0;j<route_len;++j)if(route[j]==chosen)return -1;current=chosen;route[route_len++]=current;}
    if(current!=owner)return -1;std::size_t bytes=8*static_cast<std::size_t>(route_len);if(!output||capacity<bytes)return -2;std::array<std::uint8_t,OUT> staged{};for(int i=0;i<route_len;++i)put(staged.data(),8*static_cast<std::size_t>(i),ids[route[i]]);for(std::size_t i=0;i<bytes;++i)output[i]=staged[i];return static_cast<std::int64_t>(bytes);
}

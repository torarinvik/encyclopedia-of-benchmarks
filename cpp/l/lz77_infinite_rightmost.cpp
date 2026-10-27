#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_TEXT=64,MAX_INPUT=66,MAX_OUTPUT=1536;
void put64(std::uint8_t*o,std::size_t at,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t i=0;i<8;++i){o[at+i]=static_cast<std::uint8_t>(b&255U);b>>=8;}} }
extern "C" std::int64_t lz77_infinite_rightmost(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){
    if(in==nullptr||len<1||len>MAX_INPUT||in[0]<0||in[0]>static_cast<std::int64_t>(MAX_TEXT))return -1;
    const auto n=static_cast<std::size_t>(in[0]);if(len!=n+1)return -1;
    for(std::size_t i=0;i<n;++i)if(in[i+1]<32||in[i+1]>126)return -1;
    std::uint8_t staged[MAX_OUTPUT]{};std::size_t tokens=0,q=0;
    while(q<n){std::size_t bl=0,bp=0;bool found=false;
        for(std::size_t p=0;p<q;++p){std::size_t l=0;while(q+l<n&&in[p+l+1]==in[q+l+1])++l;
            if(l>bl||(l==bl&&l>0&&(!found||p>bp))){bl=l;bp=p;found=true;}}
        const auto source_pos=found?static_cast<std::int64_t>(bp):0;const auto np=q+bl;const std::int64_t ch=np<n?in[np+1]:0;const auto at=tokens*24;
        put64(staged,at,source_pos);put64(staged,at+8,static_cast<std::int64_t>(bl));put64(staged,at+16,ch);++tokens;q=ch?np+1:np;
    }
    const auto bytes=tokens*24;if(out==nullptr||cap<bytes)return -2;for(std::size_t i=0;i<bytes;++i)out[i]=staged[i];return static_cast<std::int64_t>(bytes);
}

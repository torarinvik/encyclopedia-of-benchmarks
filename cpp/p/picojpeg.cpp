#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t floor_div_q16(std::int64_t value) {
    return value >= 0 ? value / 65536 : -((-value + 65535) / 65536);
}
bool valid(const std::int64_t* v) {
    constexpr std::array<std::uint8_t, 13> sof = {255,192,0,11,8,0,8,0,8,1,1,17,0};
    constexpr std::array<std::uint8_t, 10> sos = {255,218,0,8,1,1,0,0,63,0};
    if (v[0]!=255 || v[1]!=216 || v[2]!=255 || v[3]!=219 || v[4]!=0 || v[5]!=67 || v[6]!=0) return false;
    for (std::size_t i=0;i<64;++i) if(v[7+i]<1 || v[7+i]>255 || (i>=2 && v[7+i]!=1)) return false;
    for(std::size_t i=0;i<sof.size();++i) if(v[71+i]!=sof[i]) return false;
    if(v[84]!=255||v[85]!=196||v[86]!=0||v[87]!=39||v[88]!=0||v[89]!=1||v[90]!=0||v[105]!=4
       ||v[106]!=16||v[107]!=1||v[108]!=1||v[123]!=4||v[124]!=0) return false;
    for(std::size_t i=91;i<105;++i) if(v[i]!=0) return false;
    for(std::size_t i=109;i<123;++i) if(v[i]!=0) return false;
    for(std::size_t i=0;i<sos.size();++i) if(v[125+i]!=sos[i]) return false;
    return v[137]==255 && v[138]==217;
}
}

extern "C" std::int64_t picojpeg(const std::int64_t*,std::size_t,std::uint8_t*,std::size_t);
extern "C" std::int64_t picojpeg(const std::int64_t* v,std::size_t length,std::uint8_t* out,std::size_t capacity) {
    if(!v || length!=139) return -1;
    for(std::size_t i=0;i<length;++i) if(v[i]<0 || v[i]>255) return -1;
    if(!valid(v)) return -1;
    const std::uint16_t scan=static_cast<std::uint16_t>((v[135]<<8)|v[136]);
    if((scan&0x8000)||(scan&0x0400)||((scan>>4)&3)!=2||(scan&15)!=15) return -1;
    const int dcraw=(scan>>11)&15, acraw=(scan>>6)&15;
    const std::int64_t dc=(dcraw>=8?dcraw:dcraw-15)*v[7];
    const std::int64_t ac=(acraw>=8?acraw:acraw-15)*v[8];
    if(!out||capacity<64) return -2;
    constexpr std::array<int,8> factors={11363,9633,6436,2260,-2260,-6436,-9633,-11363};
    for(std::size_t y=0;y<8;++y) for(std::size_t x=0;x<8;++x) {
        const auto numerator=128*INT64_C(65536)+dc*8192+ac*factors[x]+32768;
        auto pixel=floor_div_q16(numerator);
        pixel=std::clamp<std::int64_t>(pixel,0,255);
        out[y*8+x]=static_cast<std::uint8_t>(pixel);
    }
    return 64;
}

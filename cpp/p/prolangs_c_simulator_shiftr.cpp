// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t prolangs_c_simulator_shiftr(const std::int64_t* v, std::size_t n) noexcept {
    if(v==nullptr || n!=2 || v[0]<0 || v[0]>255 || v[1]<0 || v[1]>0xFFFFFF) return -1;
    const auto operand=v[0]; if((operand>>4)>=10) return -1;
    const unsigned shift=static_cast<unsigned>(operand&15)+1u;
    const std::uint32_t value=static_cast<std::uint32_t>(v[1]);
    std::uint32_t result=value>>shift;
    if(value&0x800000u) result|=((1u<<shift)-1u)<<(24u-shift);
    return static_cast<std::int64_t>(result&0xFFFFFFu);
}

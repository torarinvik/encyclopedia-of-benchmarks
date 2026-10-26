// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t prolangs_c_simulator_format3_4(const std::int64_t* v, std::size_t n) noexcept {
    if (v==nullptr || n!=7) return -1;
    const auto pc=v[0], x=v[1], b=v[2];
    if (pc<0 || pc>1048572 || x<0 || x>=16777216 || b<0 || b>=16777216) return -1;
    for (std::size_t j=3;j<7;++j) if(v[j]<0 || v[j]>255) return -1;
    const int byte0=static_cast<int>(v[3]), byte1=static_cast<int>(v[4]), byte2=static_cast<int>(v[5]), byte3=static_cast<int>(v[6]);
    const int nf=(byte0>>1)&1, inf=byte0&1;
    const int xf=(byte1>>7)&1, bf=(byte1>>6)&1, pf=(byte1>>5)&1, ef=(byte1>>4)&1;
    const bool sic=nf==0 && inf==0; const int fmt=(ef && !sic)?4:3;
    const std::int64_t nextpc=pc+fmt; std::int64_t address;
    if(fmt==4) {
        if(bf || pf) return -1;
        address=(static_cast<std::int64_t>(byte1&15)<<16)|(static_cast<std::int64_t>(byte2)<<8)|byte3;
        if(xf) address+=x;
    } else {
        address=(static_cast<std::int64_t>(byte1&15)<<8)|byte2;
        if(sic) return 0; // Source's final n/i fallback returns zero for plane SIC.
        if(bf && pf) return -1;
        if(xf) address+=x;
        if(bf) address+=b;
        if(pf) address=address>=2048?address-4096+nextpc:address+nextpc;
    }
    if(nf==1 && inf==0) return -1;
    if(address<0) return -1;
    if(nf==0 && inf==1 && address>=16777216) return -1;
    return address;
}

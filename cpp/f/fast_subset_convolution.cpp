#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t mod=998244353;
int rank_of(std::size_t x) { int r=0; while(x){r+=int(x&1U);x>>=1;} return r; }
void put_i64_le(std::uint8_t *out,std::size_t off,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b)out[off+b]=std::uint8_t(u>>(8*b));}
}
extern "C" std::int64_t fast_subset_convolution(const std::int64_t *in,std::size_t len,std::uint8_t *out,std::size_t cap) noexcept {
    if(!in||len<3||len>33)return -1; const auto n0=in[0]; if(n0<0||n0>4)return -1;
    const auto n=std::size_t(n0), size=std::size_t(1)<<n; if(len!=1+2*size)return -1;
    for(std::size_t i=0;i<2*size;++i)if(in[1+i]<0||in[1+i]>=mod)return -1;
    std::int64_t f[5][16]{},g[5][16]{},h[5][16]{};
    for(std::size_t s=0;s<size;++s){int r=rank_of(s);f[r][s]=in[1+s];g[r][s]=in[1+size+s];}
    for(std::size_t bit=0;bit<n;++bit)for(std::size_t s=0;s<size;++s)if(s&(std::size_t(1)<<bit)){
        auto other=s^(std::size_t(1)<<bit);for(std::size_t r=0;r<=n;++r){f[r][s]=(f[r][s]+f[r][other])%mod;g[r][s]=(g[r][s]+g[r][other])%mod;}
    }
    for(std::size_t s=0;s<size;++s)for(std::size_t r=0;r<=n;++r){std::int64_t sum=0;for(std::size_t i=0;i<=r;++i)sum=(sum+f[i][s]*g[r-i][s])%mod;h[r][s]=sum;}
    for(std::size_t bit=0;bit<n;++bit)for(std::size_t s=0;s<size;++s)if(s&(std::size_t(1)<<bit)){
        auto other=s^(std::size_t(1)<<bit);for(std::size_t r=0;r<=n;++r)h[r][s]=(h[r][s]-h[r][other]+mod)%mod;
    }
    const auto required=size*8;if(cap<required||!out)return -2;
    for(std::size_t s=0;s<size;++s)put_i64_le(out,8*s,h[rank_of(s)][s]);return std::int64_t(required);
}

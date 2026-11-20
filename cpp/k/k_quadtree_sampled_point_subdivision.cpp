/* Clean-room sample-induced compressed quadtree split profile. */
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned b = 0; b < 8; ++b) out[at+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}

extern "C" std::int64_t k_quadtree_sampled_point_subdivision(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 68) return -1;
    const auto nv=input[0], kv=input[1], dv=input[2];
    if (nv<1 || nv>32 || kv<1 || kv>nv || dv<1 || dv>8) return -1;
    const auto n=static_cast<std::size_t>(nv), k=static_cast<std::size_t>(kv), depth=static_cast<std::size_t>(dv);
    if (length!=3+2*n) return -1;
    std::array<std::uint32_t,32> keys{};
    const auto side=std::uint32_t{1} << depth;
    for (std::size_t i=0;i<n;++i) {
        const auto x=input[3+2*i], y=input[4+2*i];
        if (x<0 || y<0 || static_cast<std::uint64_t>(x)>=side || static_cast<std::uint64_t>(y)>=side) return -1;
        std::uint32_t key=0;
        for (int bit=static_cast<int>(depth)-1;bit>=0;--bit)
            key=(key<<2)|((((static_cast<std::uint32_t>(x)>>bit)&1u)<<1)|((static_cast<std::uint32_t>(y)>>bit)&1u));
        keys[i]=key;
    }
    std::sort(keys.begin(), keys.begin()+static_cast<std::ptrdiff_t>(n));
    for(std::size_t i=1;i<n;++i) if(keys[i]==keys[i-1]) return -1;
    const auto samples=(n-1)/k+1;
    std::array<std::uint8_t,31> split_depth{};
    std::array<std::uint32_t,31> split_prefix{};
    std::size_t count=0;
    for(std::size_t i=0;i+1<samples;++i){
        const auto a=keys[i*k], b=keys[(i+1)*k]; std::size_t common=0;
        while(common<depth){const auto shift=2*(depth-common-1);if(((a>>shift)&3u)!=((b>>shift)&3u))break;++common;}
        const auto prefix=common==0?0u:a>>(2*(depth-common));
        std::size_t j=0;while(j<count&&(split_depth[j]!=common||split_prefix[j]!=prefix))++j;
        if(j==count){split_depth[count]=static_cast<std::uint8_t>(common);split_prefix[count]=prefix;++count;}
    }
    auto start=[&](std::size_t i){return split_prefix[i]<<(2*(depth-split_depth[i]));};
    for(std::size_t i=1;i<count;++i){
        const auto d=split_depth[i];
        const auto p=split_prefix[i];
        const auto s=start(i);
        std::size_t j=i;
        while(j>0){const auto ps=start(j-1);if(ps<s||(ps==s&&split_depth[j-1]<=d))break;split_depth[j]=split_depth[j-1];split_prefix[j]=split_prefix[j-1];--j;}
        split_depth[j]=d;split_prefix[j]=p;
    }
    const auto bytes=8*(1+2*count);if(output==nullptr||capacity<bytes)return -2;
    put_i64_le(output,0,static_cast<std::int64_t>(count));
    for(std::size_t i=0;i<count;++i){put_i64_le(output,8*(1+2*i),split_depth[i]);put_i64_le(output,8*(2+2*i),split_prefix[i]);}
    return static_cast<std::int64_t>(bytes);
}

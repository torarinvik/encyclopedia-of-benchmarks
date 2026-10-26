#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t prime = 2147483647;
void put_i64_le(std::uint8_t *out, std::size_t off, std::int64_t x) {
    const auto bits = static_cast<std::uint64_t>(x);
    for (std::size_t b=0; b<8; ++b) out[off+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t count_min_sketch_affine(const std::int64_t *in, std::size_t len,
                                                  std::uint8_t *out, std::size_t cap) noexcept {
    if (!in || len<3 || len>59) return -1;
    const auto d0=in[0], w0=in[1], q0=in[2];
    if (d0<1 || d0>4 || w0<1 || w0>8 || q0<0 || q0>16) return -1;
    const auto d=static_cast<std::size_t>(d0), w=static_cast<std::size_t>(w0), ops=static_cast<std::size_t>(q0);
    const auto start=3+2*d;
    if (len!=start+3*ops) return -1;
    std::int64_t a[4]{}, b[4]{};
    for (std::size_t r=0;r<d;++r) { a[r]=in[3+2*r]; b[r]=in[4+2*r]; if (a[r]<1 || a[r]>=prime || b[r]<0 || b[r]>=prime) return -1; }
    std::size_t queries=0;
    for (std::size_t op=0;op<ops;++op) {
        const auto kind=in[start+3*op], key=in[start+3*op+1], weight=in[start+3*op+2];
        if (key<0 || key>1000000) return -1;
        if (kind==0) { if (weight<1 || weight>1000000) return -1; }
        else if (kind==1) { if (weight!=0) return -1; ++queries; }
        else return -1;
    }
    std::int64_t table[4][8]{}; std::int64_t staged[16]{}; std::size_t count=0;
    for (std::size_t op=0;op<ops;++op) {
        const auto kind=in[start+3*op], key=in[start+3*op+1], weight=in[start+3*op+2];
        std::size_t slot[4]{};
        for (std::size_t r=0;r<d;++r) slot[r]=static_cast<std::size_t>(((a[r]*key+b[r])%prime)%static_cast<std::int64_t>(w));
        if (kind==0) { for (std::size_t r=0;r<d;++r) table[r][slot[r]]+=weight; }
        else { auto minimum=table[0][slot[0]]; for (std::size_t r=1;r<d;++r) if (table[r][slot[r]]<minimum) minimum=table[r][slot[r]]; staged[count++]=minimum; }
    }
    const std::size_t required=queries*8;
    if (cap<required || (required>0 && !out)) return -2;
    for (std::size_t i=0;i<count;++i) put_i64_le(out,8*i,staged[i]);
    return static_cast<std::int64_t>(required);
}

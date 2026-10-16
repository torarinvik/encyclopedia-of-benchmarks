#include <cstddef>
#include <cstdint>
#include <climits>
namespace {
void put_i64_le(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b=0;b<8;++b) out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}
extern "C" std::int64_t floor_and_ceiling(const std::int64_t* in, std::size_t length, std::uint8_t* out, std::size_t capacity) noexcept {
    if (!in || length<3 || length>384) return -1;
    const auto raw_n=in[0], root=in[1], key=in[2];
    if (raw_n<0 || raw_n>127 || key < -1000000 || key>1000000 || length!=3+3*static_cast<std::size_t>(raw_n)) return -1;
    const auto n=static_cast<std::size_t>(raw_n);
    if ((n==0 && root!=-1) || (n!=0 && (root<0 || root>=raw_n))) return -1;
    std::int64_t floor=INT64_MIN, ceiling=INT64_MIN;
    auto current=n==0?n:static_cast<std::size_t>(root);
    for (std::size_t steps=0;current<n && steps<n;++steps) {
        const auto base=3+3*current; const auto value=in[base], left=in[base+1], right=in[base+2];
        if(value < -1000000 || value>1000000 || left < -1 || right < -1 || left>=raw_n || right>=raw_n) return -1;
        if(value==key){floor=ceiling=value;break;}
        if(key<value){ceiling=value;current=left<0?n:static_cast<std::size_t>(left);}
        else {floor=value;current=right<0?n:static_cast<std::size_t>(right);}
    }
    if (!out || capacity<16) return -2;
    put_i64_le(out,0,floor); put_i64_le(out,8,ceiling); return 16;
}

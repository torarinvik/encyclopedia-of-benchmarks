#include <cstddef>
#include <cstdint>
extern "C" std::int64_t elementary(const std::int64_t *v, std::size_t n, std::uint8_t *out, std::size_t cap) noexcept {
    if (!v || n < 2 || n > 129 || v[0] < 1 || v[0] > 128 || n != static_cast<std::size_t>(v[0]) + 1) return -1;
    auto count = static_cast<std::size_t>(v[0]);
    if (v[1] != 0) return -1;
    for (std::size_t i=1;i<n;++i) if (v[i]!=0 && v[i]!=1) return -1;
    if (cap<count || !out) return -2;
    for (std::size_t i=0;i<count;++i) { unsigned l=i ? static_cast<unsigned>(v[i]) : 0u; unsigned c=static_cast<unsigned>(v[i+1]); unsigned r=i+1<count ? static_cast<unsigned>(v[i+2]) : 0u; out[i]=static_cast<std::uint8_t>((30u >> (l*4+c*2+r))&1u); }
    return static_cast<std::int64_t>(count);
}

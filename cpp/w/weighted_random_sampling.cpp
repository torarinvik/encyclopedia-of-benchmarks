#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 16, L = 50;
std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t value = 1;
    for (std::int64_t i = 0; i < exponent; ++i) value *= base;
    return value;
}
bool before(const std::int64_t *w, const std::int64_t *a, const std::int64_t *b,
            std::int64_t i, std::int64_t j) {
    auto lhs = power(a[i], w[j]) * power(b[j], w[i]);
    auto rhs = power(a[j], w[i]) * power(b[i], w[j]);
    return lhs > rhs || (lhs == rhs && i < j);
}
void put64(std::uint8_t *out, std::size_t pos, std::int64_t x) {
    auto bits = static_cast<std::uint64_t>(x);
    for (std::size_t j = 0; j < 8; ++j) { out[pos+j] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t weighted_random_sampling(const std::int64_t *in,
    std::size_t len, std::uint8_t *out, std::size_t cap) noexcept {
    if (!in || len < 5 || len > L) return -1;
    auto n64 = in[0], m64 = in[1];
    if (n64 < 1 || n64 > N || m64 < 1 || m64 > n64 || len != 2 + 3 * static_cast<std::size_t>(n64)) return -1;
    auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::int64_t w[N]{}, a[N]{}, b[N]{};
    for (std::size_t i = 0; i < n; ++i) {
        w[i]=in[2+3*i]; a[i]=in[3+3*i]; b[i]=in[4+3*i];
        if (w[i]<1 || w[i]>3 || a[i]<1 || a[i]>=b[i] || b[i]>100) return -1;
    }
    auto bytes = 8*m;
    if (!out || cap < bytes) return -2;
    std::int64_t available[N]{}, chosen[N]{};
    for (std::size_t i=0;i<n;++i) available[i]=static_cast<std::int64_t>(i);
    for (std::size_t rank=0;rank<m;++rank) {
        std::size_t best=0;
        for (std::size_t i=1;i<n-rank;++i) if (before(w,a,b,available[i],available[best])) best=i;
        chosen[rank]=available[best];
        for (std::size_t i=best;i+1<n-rank;++i) available[i]=available[i+1];
    }
    for (std::size_t i=0;i<m;++i) put64(out,8*i,chosen[i]);
    return static_cast<std::int64_t>(bytes);
}

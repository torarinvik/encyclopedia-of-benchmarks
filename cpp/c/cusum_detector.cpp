/* Two-sided CUSUM detector over a bounded integer-valued input domain. */
#include <cstddef>
#include <cstdint>
namespace {
void put_i64_le(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}
extern "C" std::int64_t cusum_detector(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 5 || input[0] < 0 || input[0] > 128) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n+5) return -1;
    const auto target=input[1], sigma=input[2], allowance=input[3], threshold=input[4];
    if (target < -1000 || target > 1000 || sigma < 1 || sigma > 1000 || allowance < 0 || allowance > 1000 || threshold < 1 || threshold > 1000) return -1;
    for (std::size_t i=0;i<n;++i) if (input[5+i] < -1000 || input[5+i] > 1000) return -1;
    if (capacity < n*8 || (n>0 && !output)) return -2;
    double upper=0.0, lower=0.0;
    for (std::size_t i=0;i<n;++i) {
        const double z=(static_cast<double>(input[5+i])-static_cast<double>(target))/static_cast<double>(sigma);
        upper=upper+z-static_cast<double>(allowance); if (upper<0.0) upper=0.0;
        lower=lower-z-static_cast<double>(allowance); if (lower<0.0) lower=0.0;
        std::int64_t signal=0;
        if (upper>static_cast<double>(threshold)) signal=1;
        else if (lower>static_cast<double>(threshold)) signal=-1;
        if (signal!=0) upper=lower=0.0;
        put_i64_le(output,i*8,signal);
    }
    return static_cast<std::int64_t>(n*8);
}

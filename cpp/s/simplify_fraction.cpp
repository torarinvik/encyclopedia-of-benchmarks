#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_abs_component = 1000000;
constexpr std::size_t output_bytes = 16;
std::uint64_t magnitude(std::int64_t value) { return value < 0 ? static_cast<std::uint64_t>(-value) : static_cast<std::uint64_t>(value); }
std::uint64_t gcd_positive(std::uint64_t a, std::uint64_t b) { while (b) { const auto r=a%b; a=b; b=r; } return a; }
void put_i64_le(std::uint8_t* out, std::size_t offset, std::int64_t value) { const auto bits=static_cast<std::uint64_t>(value); for(std::size_t i=0;i<8;++i)out[offset+i]=static_cast<std::uint8_t>(bits>>(8*i)); }
}
extern "C" std::int64_t simplify_fraction(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (!input || length != 2) return -1;
    const auto numerator=input[0], denominator=input[1];
    if(numerator < -max_abs_component || numerator > max_abs_component || denominator < -max_abs_component || denominator > max_abs_component || denominator == 0)return -1;
    const auto divisor=gcd_positive(magnitude(numerator),magnitude(denominator));
    const auto n=numerator/static_cast<std::int64_t>(divisor), d=denominator/static_cast<std::int64_t>(divisor);
    std::array<std::uint8_t,output_bytes> staged{};put_i64_le(staged.data(),0,n);put_i64_le(staged.data(),8,d);
    if(!output||capacity<output_bytes)return -2;for(std::size_t i=0;i<output_bytes;++i)output[i]=staged[i];return static_cast<std::int64_t>(output_bytes);
}

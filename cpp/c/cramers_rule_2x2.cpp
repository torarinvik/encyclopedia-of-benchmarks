#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t limit = 1'000'000;
void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte=0; byte<8; ++byte) output[offset+byte]=static_cast<std::uint8_t>(bits>>(8*byte));
}
}

extern "C" std::int64_t cramers_rule_2x2(const std::int64_t* v, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (v == nullptr || length != 6) return -1;
    for (std::size_t i=0; i<6; ++i) if (v[i] < -limit || v[i] > limit) return -1;
    const auto a1=v[0], b1=v[1], c1=v[2], a2=v[3], b2=v[4], c2=v[5];
    const auto d=a1*b2-a2*b1, dx=c1*b2-c2*b1, dy=a1*c2-a2*c1;
    if (d == 0) return -1;
    if (output == nullptr || capacity < 16) return -2;
    write_f64_le(output, 0, static_cast<double>(dx)/static_cast<double>(d));
    write_f64_le(output, 8, static_cast<double>(dy)/static_cast<double>(d));
    return 2;
}

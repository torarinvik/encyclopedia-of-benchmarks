#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::array<std::uint32_t, 32> FACTOR_LOG_32 = {
    0x00000000U, 0x00000000U, 0xd3cfd984U, 0x9ee62e18U,
    0xe83d9070U, 0xb59e81e0U, 0xa17407c0U, 0xce601f80U,
    0xf4807f00U, 0xe701fe00U, 0xbe07fc00U, 0xfc1ff800U,
    0xf87ff000U, 0xf1ffe000U, 0xe7ffc000U, 0xdfff8000U,
    0xffff0000U, 0xfffe0000U, 0xfffc0000U, 0xfff80000U,
    0xfff00000U, 0xffe00000U, 0xffc00000U, 0xff800000U,
    0xff000000U, 0xfe000000U, 0xfc000000U, 0xf8000000U,
    0xf0000000U, 0xe0000000U, 0xc0000000U, 0x80000000U
};

std::uint64_t mask_for(unsigned d) {
    return d == 32U ? UINT64_C(0xffffffff) : (UINT64_C(1) << d) - 1U;
}

std::uint64_t factoring_log(std::uint64_t remainder, std::uint64_t value,
                            unsigned d, std::uint64_t modulus, std::uint64_t mask) {
    for (unsigned bit = 2; bit < d; ++bit) {
        if ((value & (UINT64_C(1) << bit)) != 0U) {
            value = (value + (value << bit)) & mask;
            remainder = (remainder + modulus - (static_cast<std::uint64_t>(FACTOR_LOG_32[bit]) & mask)) & mask;
        }
    }
    return remainder;
}

std::uint64_t factoring_exp(std::uint64_t remainder, std::uint64_t exponent,
                            unsigned d, std::uint64_t modulus, std::uint64_t mask) {
    for (unsigned bit = 2; bit < d; ++bit) {
        if ((exponent & (UINT64_C(1) << bit)) != 0U) {
            remainder = (remainder + (remainder << bit)) & mask;
            exponent = (exponent + modulus - (static_cast<std::uint64_t>(FACTOR_LOG_32[bit]) & mask)) & mask;
        }
    }
    return remainder;
}
}

extern "C" std::int64_t factoring_exponentiation(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length != 4U) return -1;
    const auto remainder_input = input[0];
    const auto base_input = input[1];
    const auto exponent_input = input[2];
    const auto d_input = input[3];
    if (d_input < 3 || d_input > 32 || remainder_input < 0 || base_input < 1 ||
        exponent_input < 0 || exponent_input > INT64_C(4294967295)) return -1;
    const auto d = static_cast<unsigned>(d_input);
    const auto mask = mask_for(d);
    const auto modulus = mask + 1U;
    if (static_cast<std::uint64_t>(remainder_input) >= modulus ||
        static_cast<std::uint64_t>(base_input) >= modulus ||
        (static_cast<std::uint64_t>(base_input) & 1U) == 0U) return -1;

    auto remainder = static_cast<std::uint64_t>(remainder_input);
    auto base = static_cast<std::uint64_t>(base_input);
    const auto exponent = static_cast<std::uint64_t>(exponent_input);
    if ((base & 2U) != 0U) {
        base = (modulus - base) & mask;
        if ((exponent & 1U) != 0U) remainder = (modulus - remainder) & mask;
    }
    const auto log_value = factoring_log(0U, base, d, modulus, mask);
    const auto scaled_log = (log_value * exponent) & mask;
    return static_cast<std::int64_t>(factoring_exp(remainder, scaled_log, d, modulus, mask));
}

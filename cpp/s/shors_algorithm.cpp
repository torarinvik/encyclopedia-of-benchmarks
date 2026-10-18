#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MIN_MODULUS = 2;
constexpr std::int64_t MAX_MODULUS = 255;
constexpr std::int64_t MIN_ATTEMPTS = 1;
constexpr std::int64_t MAX_ATTEMPTS = 16;
constexpr std::int64_t INVALID_RESULT = -1;

std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept
{
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}
}

extern "C" std::int64_t shors_algorithm(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 3 || length > 19) return INVALID_RESULT;
    const auto modulus = packed[0];
    const auto attempts = packed[1];
    if (modulus < MIN_MODULUS || modulus > MAX_MODULUS ||
        attempts < MIN_ATTEMPTS || attempts > MAX_ATTEMPTS ||
        length != static_cast<std::size_t>(2 + attempts)) return INVALID_RESULT;
    for (std::int64_t index = 0; index < attempts; ++index) {
        const auto base = packed[2 + static_cast<std::size_t>(index)];
        if (base < 2 || base > modulus) return INVALID_RESULT;
    }

    for (std::int64_t index = 0; index < attempts; ++index) {
        const auto base = packed[2 + static_cast<std::size_t>(index)];
        const auto common = gcd_i64(base, modulus);
        if (common != 1) return common;
        std::int64_t order = 1;
        auto power = base % modulus;
        while (power != 1 && order < modulus - 1) {
            power = (power * base) % modulus;
            ++order;
        }
        if (power != 1) return INVALID_RESULT;
        if ((order & 1) != 0) continue;

        std::int64_t half_power = 1;
        for (std::int64_t exponent = 0; exponent < order / 2; ++exponent) {
            half_power = (half_power * base) % modulus;
        }
        const auto upper = half_power + 1;
        const auto lower = half_power - 1;
        if (upper % modulus == 0 || lower % modulus == 0) continue;
        const auto upper_gcd = gcd_i64(upper, modulus);
        if (upper_gcd != 1) return upper_gcd;
        return gcd_i64(lower, modulus);
    }
    return INVALID_RESULT;
}

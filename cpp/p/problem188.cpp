#include <cstdint>

namespace {
std::int64_t modexpt(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept {
    if (exponent == 1) return base;
    if (exponent % 2 == 0) {
        const auto half = modexpt(base, exponent / 2, modulus) % modulus;
        return (half * half) % modulus;
    }
    return (base * modexpt(base, exponent - 1, modulus)) % modulus;
}
}

extern "C" std::int64_t problem188(std::int64_t base, std::int64_t height, std::int64_t digits) noexcept {
    if (base < 1 || base > 1'000'000'000 || base % 10 == 0
        || height < 1 || height > 10'000 || digits < 1 || digits > 8) return -1;
    std::int64_t modulus = 1;
    for (std::int64_t index = 0; index < digits; ++index) modulus *= 10;
    std::int64_t result = base;
    for (std::int64_t level = 1; level < height; ++level) result = modexpt(base, result, modulus);
    return result;
}

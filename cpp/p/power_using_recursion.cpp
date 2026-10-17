#include <cstddef>
#include <cstdint>

namespace {
std::int64_t power_recursive(std::int64_t base, std::int64_t exponent) noexcept {
    if (exponent == 0) return 1;
    return base * power_recursive(base, exponent - 1);
}
}

extern "C" std::int64_t power_using_recursion(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto base = input[0];
    const auto exponent = input[1];
    if (base < -10 || base > 10 || exponent < 0 || exponent > 15) return -1;
    return power_recursive(base, exponent);
}

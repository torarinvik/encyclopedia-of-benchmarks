#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_exponentiation(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::uint64_t max_result = UINT64_C(9223372036854775807);
    if (values == nullptr || length != 2) return -1;
    const auto base_input = values[0], exponent_input = values[1];
    if (base_input < 0 || base_input > 2147483647 || exponent_input < 0 || exponent_input > 2147483647) return -1;
    auto base = static_cast<std::uint64_t>(base_input);
    auto exponent = static_cast<std::uint64_t>(exponent_input);
    std::uint64_t result = 1;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) {
            if (base != 0 && result > max_result / base) return -1;
            result *= base;
        }
        exponent >>= 1;
        if (exponent != 0) {
            if (base != 0 && base > max_result / base) return -1;
            base *= base;
        }
    }
    return static_cast<std::int64_t>(result);
}

#include <cstddef>
#include <cstdint>
namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_parseable_input_length = 3;
std::int64_t pow_logarithmic_value(std::int64_t base, std::uint64_t exponent) {
    if (exponent == 0) return 1;
    const auto half = pow_logarithmic_value(base, exponent / 2);
    const auto square = half * half;
    return exponent % 2 == 0 ? square : square * base;
}
}
extern "C" std::int64_t pow_logarithmic(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return invalid_result;
    if (length != 2) return invalid_result;
    const auto base = input[0], exponent = input[1];
    if (base < -10 || base > 10 || exponent < 0 || exponent > 15) return invalid_result;
    return pow_logarithmic_value(base, static_cast<std::uint64_t>(exponent));
}

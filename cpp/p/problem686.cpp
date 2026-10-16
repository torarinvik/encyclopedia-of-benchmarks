/* Find the nth power of two whose decimal prefix is 123. */
#include <cstdint>

namespace {
constexpr std::int64_t max_position = 678910;
constexpr double log10_two = 0.30102999566398114;
constexpr double lower_limit = 0.08990511143939792;
constexpr double upper_limit = 0.09342168516223506;
constexpr double round_scale = 1'000'000'000'000'000.0;
double rounded_decimal_part(std::int64_t exponent) noexcept {
    const double logarithm = log10_two * static_cast<double>(exponent);
    const auto integer_part = static_cast<std::int64_t>(logarithm);
    const double scaled = (logarithm - static_cast<double>(integer_part)) * round_scale;
    auto rounded = static_cast<std::int64_t>(scaled);
    const double remainder = scaled - static_cast<double>(rounded);
    if (remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0)) ++rounded;
    return static_cast<double>(rounded) / round_scale;
}
}
extern "C" std::int64_t problem686(std::int64_t number) noexcept {
    if (number < 1 || number > max_position) return -1;
    std::int64_t power = 90, position = 0, previous = 0;
    while (position < number) {
        const double difference = rounded_decimal_part(power);
        if (difference >= upper_limit) power += 93;
        else if (difference < lower_limit) power += 196;
        else { previous = power; power += 196; ++position; }
    }
    return previous;
}

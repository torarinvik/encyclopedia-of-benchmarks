#include <cstddef>
#include <cstdint>

extern "C" std::int64_t faraday_lenz_law(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 3 || values[0] < -1000000000 || values[0] > 1000000000 ||
        values[1] < -1000000000 || values[1] > 1000000000 || values[2] < 1 || values[2] > 1000000000)
        return INT64_MIN;
    const auto numerator = -(values[0] - values[1]) * 10;
    const auto magnitude = numerator < 0 ? -numerator : numerator;
    auto quotient = magnitude / values[2];
    const auto remainder = magnitude % values[2];
    if (2 * remainder > values[2] || (2 * remainder == values[2] && quotient % 2 != 0)) ++quotient;
    return numerator < 0 ? -quotient : quotient;
}

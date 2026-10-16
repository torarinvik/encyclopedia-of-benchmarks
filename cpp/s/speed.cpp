#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::int64_t max_speed_micro = 1000000000000000LL;
constexpr double max_rounded_milli = 9007199254740992.0;
constexpr double to_kmh_factors[7] = {
    1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1079252848.8
};
constexpr double from_kmh_factors[7] = {
    1.0, 0.277777778, 0.621371192, 0.539956803,
    0.911344415, 0.000816164, 9.265669311e-10
};

double round_three_away(double scaled) {
    if (scaled == 0.0) return scaled / 1000.0;
    const bool negative = scaled < 0.0;
    const double magnitude = negative ? -scaled : scaled;
    auto rounded_milli = static_cast<std::uint64_t>(magnitude);
    if (magnitude - static_cast<double>(rounded_milli) >= 0.5) ++rounded_milli;
    const double rounded = static_cast<double>(rounded_milli) / 1000.0;
    return negative ? -rounded : rounded;
}
}

extern "C" double speed(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 3) return invalid_result;
    const auto speed_micro = values[0];
    const auto from_unit = values[1];
    const auto to_unit = values[2];
    if (speed_micro < -max_speed_micro || speed_micro > max_speed_micro ||
        from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6) return invalid_result;
    const double speed_value = static_cast<double>(speed_micro) / 1000000.0;
    const double kmh = speed_value * to_kmh_factors[from_unit];
    const double result = kmh * from_kmh_factors[to_unit];
    const double scaled = result * 1000.0;
    if (scaled > max_rounded_milli || scaled < -max_rounded_milli) return invalid_result;
    return round_three_away(scaled);
}

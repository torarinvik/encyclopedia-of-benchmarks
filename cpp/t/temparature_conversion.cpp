#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxAbsTemperatureMicro = 1'000'000'000'000;
constexpr std::size_t kMaxInputLength = 4;
constexpr double kInvalidResult = -1.0e300;

double round_nearest_ties_even(double value) noexcept
{
    const double lower = std::floor(value);
    const double fraction = value - lower;
    if (fraction < 0.5) return lower;
    if (fraction > 0.5) return lower + 1.0;
    const auto integer = static_cast<std::int64_t>(lower);
    return integer % 2 == 0 ? lower : lower + 1.0;
}

double round_digits(double value, std::int64_t digits) noexcept
{
    double scale = 1.0;
    const std::int64_t magnitude = digits < 0 ? -digits : digits;
    for (std::int64_t index = 0; index < magnitude; ++index) scale *= 10.0;
    const double scaled = digits >= 0 ? value * scale : value / scale;
    const double rounded = round_nearest_ties_even(scaled);
    return digits >= 0 ? rounded / scale : rounded * scale;
}
}

extern "C" double temparature_conversion(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInputLength) return kInvalidResult;
    const std::int64_t operation = input[0];
    const std::int64_t temperature_micro = input[1];
    const std::int64_t digits = input[2];
    if (length != 3 || operation < 0 || operation > 5
            || temperature_micro < -kMaxAbsTemperatureMicro || temperature_micro > kMaxAbsTemperatureMicro
            || digits < -6 || digits > 6) return kInvalidResult;

    const double temperature = static_cast<double>(temperature_micro) / 1'000'000.0;
    double result;
    switch (operation) {
        case 0: result = temperature * 1.8 + 32.0; break;
        case 1: result = temperature + 273.15; break;
        case 2: result = (temperature - 32.0) * 5.0 / 9.0; break;
        case 3: result = (temperature - 32.0) * 5.0 / 9.0 + 273.15; break;
        case 4: result = temperature - 273.15; break;
        case 5: result = (temperature - 273.15) * 1.8 + 32.0; break;
        default: return kInvalidResult;
    }
    return round_digits(result, digits);
}

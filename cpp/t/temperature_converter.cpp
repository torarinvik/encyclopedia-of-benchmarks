/* Six direct conversions from the pinned Java TemperatureConverter source. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxAbsTemperatureMicro = 1'000'000'000'000;
constexpr std::size_t kMaxInputLength = 3;
constexpr double kInvalidResult = -1.0e300;
}

extern "C" double temperature_converter(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2 || length > kMaxInputLength) return kInvalidResult;
    const std::int64_t operation = values[0];
    const std::int64_t temperature_micro = values[1];
    if (temperature_micro < -kMaxAbsTemperatureMicro || temperature_micro > kMaxAbsTemperatureMicro)
        return kInvalidResult;
    const double temperature = static_cast<double>(temperature_micro) / 1'000'000.0;
    switch (operation) {
        case 0: return temperature * 9.0 / 5.0 + 32.0;
        case 1: return temperature + 273.15;
        case 2: return (temperature - 32.0) * 5.0 / 9.0;
        case 3: return (temperature - 32.0) * 5.0 / 9.0 + 273.15;
        case 4: return temperature - 273.15;
        case 5: return (temperature - 273.15) * 9.0 / 5.0 + 32.0;
        default: return kInvalidResult;
    }
}

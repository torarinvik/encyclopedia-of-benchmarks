// Real/reactive power from apparent power and power factor.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double real_and_reactive_power(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t operation = values[0];
    const std::int64_t apparent_power = values[1];
    const std::int64_t factor_units = values[2];
    if ((operation != 0 && operation != 1) || apparent_power < -1000000000LL ||
        apparent_power > 1000000000LL || factor_units < -10000 || factor_units > 10000)
        return -1.0e300;
    const double power_factor = static_cast<double>(factor_units) / 10000.0;
    if (operation == 0) return static_cast<double>(apparent_power) * power_factor;
    return static_cast<double>(apparent_power) * std::sqrt(1.0 - std::pow(power_factor, 2.0));
}

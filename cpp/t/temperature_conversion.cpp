#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::int64_t invalid_result = std::numeric_limits<std::int64_t>::min();

double convert_temperature(std::int64_t operation, double value) {
    switch (operation) {
        case 0: return (value * 9.0) / 5.0 + 32.0;
        case 1: return value + 273.15;
        case 2: return (value * 9.0) / 5.0 + 491.67;
        case 3: return ((value - 32.0) * 5.0) / 9.0;
        case 4: return ((value - 32.0) * 5.0) / 9.0 + 273.15;
        case 5: return value + 459.67;
        case 6: return value - 273.15;
        case 7: return ((value - 273.15) * 9.0) / 5.0 + 32.0;
        case 8: return (value * 9.0) / 5.0;
        case 9: return ((value - 491.67) * 5.0) / 9.0;
        case 10: return value - 459.67;
        case 11: return (value * 5.0) / 9.0;
        case 12: return value * 1.25;
        case 13: return value * 2.25 + 32.0;
        case 14: return value * 1.25 + 273.15;
        case 15: return value * 2.25 + 32.0 + 459.67;
        default: return 0.0;
    }
}
}

extern "C" std::int64_t temperature_conversion(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t operation = values[0];
    const std::int64_t temperature = values[1];
    if (operation < 0 || operation > 15 || temperature < -1000000 || temperature > 1000000) return invalid_result;
    return static_cast<std::int64_t>(std::floor(convert_temperature(operation, static_cast<double>(temperature)) + 0.5));
}

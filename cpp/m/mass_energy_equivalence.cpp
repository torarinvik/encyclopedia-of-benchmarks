// Mass-energy equivalence, with an operation selector for both source APIs.
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double SPEED_OF_LIGHT = 299792458.0;
constexpr double SPEED_OF_LIGHT_SQUARED = SPEED_OF_LIGHT * SPEED_OF_LIGHT;
}

extern "C" double mass_energy_equivalence(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto operation = values[0], value = values[1];
    if ((operation != 0 && operation != 1) || value < 0 || value > INT64_C(1000000000)) return INVALID_RESULT;
    if (operation == 0) return static_cast<double>(value) * SPEED_OF_LIGHT_SQUARED;
    return static_cast<double>(value) / SPEED_OF_LIGHT_SQUARED;
}

// PN junction built-in voltage over bounded integer concentrations.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double BOLTZMANN = 1.380649e-23; constexpr double ELECTRON_VOLT = 1.602176634e-19; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double builtin_voltage(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto donor = values[0];
    const auto acceptor = values[1];
    const auto intrinsic = values[2];
    if (donor < 1 || donor > 1000 || acceptor < 1 || acceptor > 1000 || intrinsic < 1 || intrinsic > 1000 ||
        donor <= intrinsic || acceptor <= intrinsic) return INVALID_RESULT;
    const double ratio = (static_cast<double>(donor) * static_cast<double>(acceptor)) /
        (static_cast<double>(intrinsic) * static_cast<double>(intrinsic));
    return BOLTZMANN * 300.0 * std::log(ratio) / ELECTRON_VOLT;
}

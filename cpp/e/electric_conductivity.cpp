// Solve one quantity in conductivity = electron concentration * mobility * charge.
#include <cstddef>
#include <cstdint>

namespace { constexpr double ELECTRON_CHARGE = 1.6021e-19; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double electric_conductivity(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto conductivity = values[0];
    const auto electron_conc = values[1];
    const auto mobility = values[2];
    if (conductivity < 0 || conductivity > 1000 || electron_conc < 0 || electron_conc > 1000 || mobility < 0 || mobility > 1000) return INVALID_RESULT;
    const int zeros = (conductivity == 0) + (electron_conc == 0) + (mobility == 0);
    if (zeros != 1) return INVALID_RESULT;
    if (conductivity == 0) return static_cast<double>(mobility) * static_cast<double>(electron_conc) * ELECTRON_CHARGE;
    if (electron_conc == 0) return static_cast<double>(conductivity) / (static_cast<double>(mobility) * ELECTRON_CHARGE);
    return static_cast<double>(conductivity) / (static_cast<double>(electron_conc) * ELECTRON_CHARGE);
}

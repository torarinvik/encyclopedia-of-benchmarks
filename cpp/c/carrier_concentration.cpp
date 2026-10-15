// Solve the missing semiconductor carrier concentration.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double carrier_concentration(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t electron_conc = values[0];
    const std::int64_t hole_conc = values[1];
    const std::int64_t intrinsic_conc = values[2];
    if (electron_conc < 0 || electron_conc > 1'000'000 || hole_conc < 0 || hole_conc > 1'000'000 ||
        intrinsic_conc < 0 || intrinsic_conc > 1'000'000) return -1.0e300;
    const int zero_count = (electron_conc == 0) + (hole_conc == 0) + (intrinsic_conc == 0);
    if (zero_count != 1) return -1.0e300;
    if (electron_conc == 0) return static_cast<double>(intrinsic_conc * intrinsic_conc) / static_cast<double>(hole_conc);
    if (hole_conc == 0) return static_cast<double>(intrinsic_conc * intrinsic_conc) / static_cast<double>(electron_conc);
    return std::pow(static_cast<double>(electron_conc * hole_conc), 0.5);
}

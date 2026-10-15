// Pressure from the ideal gas law: n * T * R / V.
#include <cstddef>
#include <cstdint>

extern "C" double ideal_gas_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t moles = values[0];
    const std::int64_t kelvin = values[1];
    const std::int64_t volume = values[2];
    if (moles < 0 || moles > 1000 || kelvin < 0 || kelvin > 1000 || volume < 1 || volume > 1000)
        return -1.0e300;
    return (static_cast<double>(moles) * static_cast<double>(kelvin) * 8.314462) / static_cast<double>(volume);
}

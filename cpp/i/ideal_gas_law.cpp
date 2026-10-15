// Pressure from the ideal gas law: n * T * R / V.
#include <cstddef>
#include <cstdint>

extern "C" double ideal_gas_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return -1.0e300;
    const std::int64_t operation = values[0];
    const std::int64_t a = values[1], b = values[2], c = values[3];
    if (operation < 0 || operation > 3 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000)
        return -1.0e300;
    if (operation == 0 || operation == 1) {
        if (c == 0) return -1.0e300;
        return (static_cast<double>(a) * static_cast<double>(b) * 8.314462) / static_cast<double>(c);
    }
    if (a == 0) return -1.0e300;
    return (static_cast<double>(c) * static_cast<double>(b)) / (static_cast<double>(a) * 8.314462);
}

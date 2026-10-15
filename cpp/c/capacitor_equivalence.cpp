// Equivalent capacitance for series and parallel connections.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double capacitor_equivalence(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 33) return INVALID_RESULT;
    const auto operation = values[0];
    if (operation != 0 && operation != 1) return INVALID_RESULT;
    double accumulated = 0.0;
    for (std::size_t index = 1; index < length; ++index) {
        const auto capacitor = values[index];
        if (capacitor < (operation == 0 ? 0 : 1) || capacitor > 1000) return INVALID_RESULT;
        if (operation == 0) accumulated += static_cast<double>(capacitor);
        else accumulated += 1.0 / static_cast<double>(capacitor);
    }
    return operation == 0 ? accumulated : 1.0 / accumulated;
}

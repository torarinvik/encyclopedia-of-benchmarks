// Series and parallel resistor equivalents.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double resistor_equivalence(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 33) return INVALID_RESULT;
    const auto operation = values[0];
    if (operation != 0 && operation != 1) return INVALID_RESULT;
    double accumulated = 0.0;
    for (std::size_t index = 1; index < length; ++index) {
        const auto resistor = values[index];
        if (resistor < (operation == 0 ? 1 : 0) || resistor > 1000) return INVALID_RESULT;
        if (operation == 0) accumulated += 1.0 / static_cast<double>(resistor);
        else accumulated += static_cast<double>(resistor);
    }
    return operation == 0 ? 1.0 / accumulated : accumulated;
}

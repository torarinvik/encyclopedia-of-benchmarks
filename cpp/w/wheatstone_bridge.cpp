// Solve the unknown resistance in a balanced Wheatstone bridge.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double wheatstone_bridge(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto resistance_1 = values[0];
    const auto resistance_2 = values[1];
    const auto resistance_3 = values[2];
    if (resistance_1 < 1 || resistance_1 > 1000000 ||
        resistance_2 < 1 || resistance_2 > 1000000 ||
        resistance_3 < 1 || resistance_3 > 1000000) return INVALID_RESULT;
    return (static_cast<double>(resistance_2) / static_cast<double>(resistance_1)) *
           static_cast<double>(resistance_3);
}

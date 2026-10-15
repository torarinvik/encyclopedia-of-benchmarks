#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

// Operation 0 tests a geometric sequence; operation 1 computes its mean.
extern "C" double geometric(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return INVALID_RESULT;
    const auto operation = values[0];
    const std::size_t count = length - 1;
    if (operation == 0) {
        if (count > 16) return INVALID_RESULT;
        for (std::size_t i = 1; i < length; ++i)
            if (values[i] < -100 || values[i] > 100) return INVALID_RESULT;
        if (count == 1) return 1.0;
        if (values[1] == 0) return 0.0;
        const double common_ratio = static_cast<double>(values[2]) / static_cast<double>(values[1]);
        for (std::size_t i = 0; i + 1 < count; ++i) {
            if (values[i + 1] == 0) return 0.0;
            if (static_cast<double>(values[i + 2]) / static_cast<double>(values[i + 1]) != common_ratio)
                return 0.0;
        }
        return 1.0;
    }
    if (operation == 1) {
        if (count > 7) return INVALID_RESULT;
        std::int64_t product = 1;
        for (std::size_t i = 1; i < length; ++i) {
            if (values[i] < 0 || values[i] > 100) return INVALID_RESULT;
            product *= values[i];
        }
        return std::pow(static_cast<double>(product), 1.0 / static_cast<double>(count));
    }
    return INVALID_RESULT;
}

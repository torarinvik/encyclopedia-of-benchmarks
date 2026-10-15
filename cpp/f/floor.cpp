/* Floor for bounded finite binary64 inputs, correcting truncation below zero. */
#include <cstdint>

extern "C" double floor(double value) noexcept
{
    if (value < -1000000.0 || value > 1000000.0) {
        return -1.0;
    }
    std::int64_t result = static_cast<std::int64_t>(value);
    if (value < static_cast<double>(result)) {
        --result;
    }
    return static_cast<double>(result);
}

/* Cross-platform scalar implementation of return_on_investment. */
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double return_on_investment(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t gain = values[0];
    const std::int64_t cost = values[1];
    if (gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000) return invalid_result;
    return (static_cast<double>(gain) - static_cast<double>(cost)) / static_cast<double>(cost);
}

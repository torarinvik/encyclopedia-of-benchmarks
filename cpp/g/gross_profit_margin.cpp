/* Cross-platform scalar implementation of gross_profit_margin. */
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double gross_profit_margin(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t revenue = values[0];
    const std::int64_t cost = values[1];
    if (revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000) return invalid_result;
    return (static_cast<double>(revenue) - static_cast<double>(cost)) / static_cast<double>(revenue);
}

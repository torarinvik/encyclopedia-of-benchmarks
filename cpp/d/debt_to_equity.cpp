/* Cross-platform scalar implementation of debt_to_equity. */
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double debt_to_equity(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t debt = values[0];
    const std::int64_t equity = values[1];
    if (debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000) return invalid_result;
    return static_cast<double>(debt) / static_cast<double>(equity);
}

/* Cross-platform scalar implementation of earnings_per_sale. */
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double earnings_per_sale(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 3) return invalid_result;
    const std::int64_t net_income = values[0];
    const std::int64_t preferred_dividend = values[1];
    const std::int64_t average_shares = values[2];
    if (net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000) return invalid_result;
    return (static_cast<double>(net_income) - static_cast<double>(preferred_dividend)) / static_cast<double>(average_shares);
}

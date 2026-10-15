#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double equated_monthly_installments(double principal, double rate_per_annum,
                                                double years_to_repay) noexcept
{
    if (std::isnan(principal) || std::isnan(rate_per_annum) || std::isnan(years_to_repay) ||
        principal <= 0.0 || principal > 1000000.0 || rate_per_annum < 0.0001 || rate_per_annum > 0.2 ||
        years_to_repay < 1.0 || years_to_repay > 30.0 || std::floor(years_to_repay) != years_to_repay) return INVALID_RESULT;
    const double monthly_rate = rate_per_annum / 12.0;
    const double payments = years_to_repay * 12.0;
    const double factor = std::pow(1.0 + monthly_rate, payments);
    return principal * monthly_rate * factor / (factor - 1.0);
}

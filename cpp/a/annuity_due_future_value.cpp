// Future value of an annuity due using the pinned source formula.
#include <cmath>

extern "C" double annuity_due_future_value(double payment, double periods, double rate) noexcept
{
    const double annuity_factor = (std::pow(1.0 + rate, periods) - 1.0) / rate;
    return payment * annuity_factor * (1.0 + rate);
}

/* Future value of an annuity due using the pinned source formula. */
#include <math.h>

double annuity_due_future_value(double payment, double periods, double rate)
{
    const double annuity_factor = (pow(1.0 + rate, periods) - 1.0) / rate;
    return payment * annuity_factor * (1.0 + rate);
}

/* Ordinary annuity future value using the pinned source formula. */
#include <math.h>

double ordinary_annuity_future_value(double term_payment, double number_of_payments, double term_interest_rate)
{
    const double annuity_factor = (pow(1.0 + term_interest_rate, number_of_payments) - 1.0) / term_interest_rate;
    return term_payment * annuity_factor;
}

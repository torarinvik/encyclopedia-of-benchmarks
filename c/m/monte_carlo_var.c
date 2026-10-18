#include "monte_carlo_risk_impl.h"

int64_t monte_carlo_var(const double *input, size_t input_length,
                        double *output, size_t output_capacity)
{
    return monte_carlo_risk_impl(input, input_length, output, output_capacity, 0);
}

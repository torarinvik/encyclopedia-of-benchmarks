#include "monte_carlo_risk_impl.hpp"

extern "C" std::int64_t monte_carlo_var(const double *input, std::size_t input_length,
                                         double *output, std::size_t output_capacity) noexcept
{
    return monte_carlo_risk_impl(input, input_length, output, output_capacity, false);
}

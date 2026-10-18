#include "monte_carlo_risk_impl.hpp"

extern "C" std::int64_t monte_carlo_expected_shortfall(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity) noexcept
{
    return monte_carlo_risk_impl(input, input_length, output, output_capacity, true);
}

#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_simulations = 32;
constexpr std::size_t max_parseable_input_length = 520;

bool allowed_step_count(double value) noexcept
{
    return value == 1.0 || value == 2.0 || value == 4.0 ||
           value == 8.0 || value == 16.0;
}

bool allowed_maturity(double value) noexcept
{
    return value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0;
}
} // namespace

extern "C" std::int64_t monte_carlo_simulation(const double* values, std::size_t length,
                                               double* output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 7 || length > max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!std::isfinite(values[index])) return -1;

    const double s0 = values[0];
    const double strike = values[1];
    const double rate = values[2];
    const double volatility = values[3];
    const double maturity = values[4];
    const double step_value = values[5];
    const double simulation_value = values[6];
    if (s0 < 1.0 || s0 > 1000.0 || strike < 0.0 || strike > 2000.0 ||
        rate < -0.25 || rate > 0.25 || volatility < 0.0 || volatility > 0.5 ||
        !allowed_maturity(maturity) || !allowed_step_count(step_value) ||
        simulation_value < 1.0 || simulation_value > static_cast<double>(max_simulations) ||
        std::trunc(simulation_value) != simulation_value) return -1;

    const std::size_t steps = static_cast<std::size_t>(step_value);
    const std::size_t simulations = static_cast<std::size_t>(simulation_value);
    if (length != 7 + steps * simulations) return -1;
    for (std::size_t index = 7; index < length; ++index)
        if (values[index] < -3.0 || values[index] > 3.0) return -1;

    const double dt = maturity / static_cast<double>(steps);
    const double sqrt_dt = std::sqrt(dt);
    const double drift_rate = rate - 0.5 * (volatility * volatility);
    const double drift = drift_rate * maturity;
    double payoffs[max_simulations]{};
    for (std::size_t simulation = 0; simulation < simulations; ++simulation) {
        double brownian = 0.0;
        const std::size_t offset = 7 + simulation * steps;
        for (std::size_t step = 0; step < steps; ++step)
            brownian += sqrt_dt * values[offset + step];
        const double exponent = drift + volatility * brownian;
        const double terminal_price = s0 * std::exp(exponent);
        const double difference = terminal_price - strike;
        payoffs[simulation] = difference > 0.0 ? difference : 0.0;
    }

    double total = 0.0;
    for (std::size_t simulation = 0; simulation < simulations; ++simulation)
        total += payoffs[simulation];
    const double option_price = (total / static_cast<double>(simulations)) * std::exp(-rate * maturity);
    if (!std::isfinite(option_price)) return -1;

    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = option_price;
    return 1;
}

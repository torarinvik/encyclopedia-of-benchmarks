#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_SIMULATIONS = 32,
    MAX_PARSEABLE_INPUT_LENGTH = 520
};

static int finite_value(double value)
{
    return isfinite(value) != 0;
}

static int allowed_step_count(double value)
{
    return value == 1.0 || value == 2.0 || value == 4.0 ||
           value == 8.0 || value == 16.0;
}

static int allowed_maturity(double value)
{
    return value == 0.25 || value == 0.5 || value == 1.0 || value == 2.0;
}

int64_t monte_carlo_simulation(const double *values, size_t length,
                               double *output, size_t output_capacity)
{
    if (values == NULL || length < 7u || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!finite_value(values[index])) return -1;

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
        simulation_value < 1.0 || simulation_value > (double)MAX_SIMULATIONS ||
        simulation_value != trunc(simulation_value)) return -1;

    const size_t steps = (size_t)step_value;
    const size_t simulations = (size_t)simulation_value;
    if (length != 7u + steps * simulations) return -1;
    for (size_t index = 7u; index < length; ++index)
        if (values[index] < -3.0 || values[index] > 3.0) return -1;

    const double dt = maturity / (double)steps;
    const double sqrt_dt = sqrt(dt);
    const double drift_rate = rate - 0.5 * (volatility * volatility);
    const double drift = drift_rate * maturity;
    double payoffs[MAX_SIMULATIONS] = {0.0};
    for (size_t simulation = 0; simulation < simulations; ++simulation) {
        double brownian = 0.0;
        const size_t offset = 7u + simulation * steps;
        for (size_t step = 0; step < steps; ++step)
            brownian += sqrt_dt * values[offset + step];
        const double exponent = drift + volatility * brownian;
        const double terminal_price = s0 * exp(exponent);
        const double difference = terminal_price - strike;
        payoffs[simulation] = difference > 0.0 ? difference : 0.0;
    }

    double total = 0.0;
    for (size_t simulation = 0; simulation < simulations; ++simulation)
        total += payoffs[simulation];
    const double option_price = (total / (double)simulations) * exp(-rate * maturity);
    if (!finite_value(option_price)) return -1;

    if (output == NULL || output_capacity < 1u) return -2;
    output[0] = option_price;
    return 1;
}

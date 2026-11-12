#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_steps = 8;
constexpr std::size_t max_factors = 3;
constexpr std::size_t max_input = 54;
constexpr std::size_t max_output = max_steps * max_steps;

bool integer_in_range(double value, double minimum, double maximum) noexcept
{
    return std::isfinite(value) && value >= minimum && value <= maximum
        && std::trunc(value) == value;
}
}

extern "C" std::int64_t hjm_forward_path(const double *input, std::size_t input_length,
                                         double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 7 || input_length > max_input) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }
    if (!integer_in_range(input[0], 2.0, static_cast<double>(max_steps))
        || !integer_in_range(input[1], 1.0, static_cast<double>(max_factors))) return -1;

    const auto steps = static_cast<std::size_t>(input[0]);
    const auto factors = static_cast<std::size_t>(input[1]);
    const double years = input[2];
    if (years != 1.0 && years != 2.0 && years != 3.0) return -1;
    const std::size_t expected = 3 + steps + 2 * factors * (steps - 1);
    if (input_length != expected) return -1;

    double yields[max_steps]{};
    double vols[max_factors][max_steps - 1]{};
    double shocks[max_steps - 1][max_factors]{};
    double forwards[max_steps]{};
    double factor_drifts[max_factors][max_steps - 1]{};
    double total_drifts[max_steps - 1]{};
    double path[max_output]{};

    std::size_t cursor = 3;
    for (std::size_t i = 0; i < steps; ++i) {
        yields[i] = input[cursor++];
        if (yields[i] < -0.05 || yields[i] > 0.20) return -1;
    }
    for (std::size_t factor = 0; factor < factors; ++factor) {
        for (std::size_t maturity = 0; maturity < steps - 1; ++maturity) {
            const double volatility = input[cursor++];
            if (volatility < 0.0 || volatility > 0.30) return -1;
            vols[factor][maturity] = volatility;
        }
    }
    for (std::size_t time = 0; time < steps - 1; ++time) {
        for (std::size_t factor = 0; factor < factors; ++factor) {
            const double shock = input[cursor++];
            if (shock < -3.0 || shock > 3.0) return -1;
            shocks[time][factor] = shock;
        }
    }

    const double dt = years / static_cast<double>(steps);
    forwards[0] = yields[0];
    for (std::size_t maturity = 1; maturity < steps; ++maturity) {
        forwards[maturity] = static_cast<double>(maturity + 1) * yields[maturity]
                           - static_cast<double>(maturity) * yields[maturity - 1];
    }
    for (std::size_t factor = 0; factor < factors; ++factor) {
        factor_drifts[factor][0] = 0.5 * dt * vols[factor][0] * vols[factor][0];
        for (std::size_t maturity = 1; maturity < steps - 1; ++maturity) {
            double drift = 0.0;
            for (std::size_t prior = 0; prior < maturity; ++prior) drift -= factor_drifts[factor][prior];
            double prefix_volatility = 0.0;
            for (std::size_t prior = 0; prior <= maturity; ++prior) prefix_volatility += vols[factor][prior];
            drift += 0.5 * dt * prefix_volatility * prefix_volatility;
            factor_drifts[factor][maturity] = drift;
        }
    }
    for (std::size_t maturity = 0; maturity < steps - 1; ++maturity) {
        for (std::size_t factor = 0; factor < factors; ++factor) {
            total_drifts[maturity] += factor_drifts[factor][maturity];
        }
    }
    for (std::size_t maturity = 0; maturity < steps; ++maturity) path[maturity] = forwards[maturity];
    const double root_dt = std::sqrt(dt);
    for (std::size_t time = 1; time < steps; ++time) {
        for (std::size_t maturity = 0; maturity < steps - time; ++maturity) {
            double total_shock = 0.0;
            for (std::size_t factor = 0; factor < factors; ++factor) {
                total_shock += vols[factor][maturity] * shocks[time - 1][factor];
            }
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1]
                + total_drifts[maturity] * dt + root_dt * total_shock;
        }
    }

    const std::size_t needed = steps * steps;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = path[i];
    return static_cast<std::int64_t>(needed);
}

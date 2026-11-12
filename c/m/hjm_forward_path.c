#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 8u
#define MAX_FACTORS 3u
#define MAX_INPUT 54u
#define MAX_OUTPUT (MAX_STEPS * MAX_STEPS)

static int is_integer_in_range(double value, double minimum, double maximum)
{
    return isfinite(value) && value >= minimum && value <= maximum && trunc(value) == value;
}

int64_t hjm_forward_path(const double *input, size_t input_length,
                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 7 || input_length > MAX_INPUT) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }
    if (!is_integer_in_range(input[0], 2.0, (double)MAX_STEPS)
        || !is_integer_in_range(input[1], 1.0, (double)MAX_FACTORS)) return -1;

    const size_t steps = (size_t)input[0];
    const size_t factors = (size_t)input[1];
    const double years = input[2];
    if (years != 1.0 && years != 2.0 && years != 3.0) return -1;
    const size_t expected = 3 + steps + 2 * factors * (steps - 1);
    if (input_length != expected) return -1;

    double yields[MAX_STEPS] = {0.0};
    double vols[MAX_FACTORS][MAX_STEPS - 1] = {{0.0}};
    double shocks[MAX_STEPS - 1][MAX_FACTORS] = {{0.0}};
    double forwards[MAX_STEPS] = {0.0};
    double factor_drifts[MAX_FACTORS][MAX_STEPS - 1] = {{0.0}};
    double total_drifts[MAX_STEPS - 1] = {0.0};
    double path[MAX_OUTPUT] = {0.0};

    size_t cursor = 3;
    for (size_t i = 0; i < steps; ++i) {
        yields[i] = input[cursor++];
        if (yields[i] < -0.05 || yields[i] > 0.20) return -1;
    }
    for (size_t factor = 0; factor < factors; ++factor) {
        for (size_t maturity = 0; maturity < steps - 1; ++maturity) {
            const double volatility = input[cursor++];
            if (volatility < 0.0 || volatility > 0.30) return -1;
            vols[factor][maturity] = volatility;
        }
    }
    for (size_t time = 0; time < steps - 1; ++time) {
        for (size_t factor = 0; factor < factors; ++factor) {
            const double shock = input[cursor++];
            if (shock < -3.0 || shock > 3.0) return -1;
            shocks[time][factor] = shock;
        }
    }

    const double dt = years / (double)steps;
    forwards[0] = yields[0];
    for (size_t maturity = 1; maturity < steps; ++maturity) {
        forwards[maturity] = (double)(maturity + 1) * yields[maturity]
                           - (double)maturity * yields[maturity - 1];
    }

    for (size_t factor = 0; factor < factors; ++factor) {
        factor_drifts[factor][0] = 0.5 * dt * vols[factor][0] * vols[factor][0];
        for (size_t maturity = 1; maturity < steps - 1; ++maturity) {
            double drift = 0.0;
            for (size_t prior = 0; prior < maturity; ++prior) {
                drift -= factor_drifts[factor][prior];
            }
            double prefix_volatility = 0.0;
            for (size_t prior = 0; prior <= maturity; ++prior) {
                prefix_volatility += vols[factor][prior];
            }
            drift += 0.5 * dt * prefix_volatility * prefix_volatility;
            factor_drifts[factor][maturity] = drift;
        }
    }
    for (size_t maturity = 0; maturity < steps - 1; ++maturity) {
        for (size_t factor = 0; factor < factors; ++factor) {
            total_drifts[maturity] += factor_drifts[factor][maturity];
        }
    }

    for (size_t maturity = 0; maturity < steps; ++maturity) {
        path[maturity] = forwards[maturity];
    }
    const double root_dt = sqrt(dt);
    for (size_t time = 1; time < steps; ++time) {
        for (size_t maturity = 0; maturity < steps - time; ++maturity) {
            double total_shock = 0.0;
            for (size_t factor = 0; factor < factors; ++factor) {
                total_shock += vols[factor][maturity] * shocks[time - 1][factor];
            }
            path[time * steps + maturity] = path[(time - 1) * steps + maturity + 1]
                + total_drifts[maturity] * dt + root_dt * total_shock;
        }
    }

    const size_t needed = steps * steps;
    if (output == NULL || output_capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = path[i];
    return (int64_t)needed;
}

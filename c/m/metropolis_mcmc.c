#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_STATES = 8, MAX_STEPS = 64, MAX_INPUT = 140 };

static int bounded_integer(double value, double minimum, double maximum) {
    return isfinite(value) && trunc(value) == value && value >= minimum && value <= maximum;
}

int64_t metropolis_mcmc(const double *input, size_t length, double *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (!bounded_integer(input[0], 1.0, MAX_STATES) ||
        !bounded_integer(input[1], 0.0, MAX_STEPS)) return -1;
    const size_t states = (size_t)input[0];
    const size_t steps = (size_t)input[1];
    if (!bounded_integer(input[2], 0.0, (double)(states - 1)) ||
        !isfinite(input[3]) || input[3] < 0.001 || input[3] > 1000.0 ||
        length != 4 + states + 2 * steps) return -1;
    for (size_t state = 0; state < states; ++state)
        if (!isfinite(input[4 + state]) || fabs(input[4 + state]) > 1000000.0) return -1;
    const size_t proposal_start = 4 + states;
    const size_t uniform_start = proposal_start + steps;
    for (size_t step = 0; step < steps; ++step) {
        if (!bounded_integer(input[proposal_start + step], 0.0, (double)(states - 1)) ||
            !isfinite(input[uniform_start + step]) || input[uniform_start + step] < 0.0 ||
            input[uniform_start + step] >= 1.0) return -1;
    }
    if (output == NULL || capacity < steps + 1) return -2;

    size_t current = (size_t)input[2];
    output[0] = (double)current;
    for (size_t step = 0; step < steps; ++step) {
        const size_t proposal = (size_t)input[proposal_start + step];
        const double delta = (input[4 + proposal] - input[4 + current]) / input[3];
        if (delta <= 0.0) current = proposal;
        else if (input[uniform_start + step] < exp(-delta)) current = proposal;
        output[step + 1] = (double)current;
    }
    return (int64_t)(steps + 1);
}

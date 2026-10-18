/* Perform one deterministic Q-learning update on a fresh bounded table. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NEXT_ACTIONS 4
#define MAX_VALID_INPUT_LENGTH 10
#define MAX_PARSEABLE_INPUT_LENGTH 11

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
    return result;
}

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static int exact_action_count(double value, size_t *count)
{
    if (!isfinite(value) || value < 0.0 || value > (double)MAX_NEXT_ACTIONS) return 0;
    const size_t converted = (size_t)value;
    if ((double)converted != value) return 0;
    *count = converted;
    return 1;
}

int64_t q_learning_update(const double *input, size_t input_length,
                          double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 6 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index)
        if (!isfinite(input[index])) return -1;

    if (input[0] != 0.0 && input[0] != 1.0) return -1;
    const double alpha = input[1];
    const double gamma = input[2];
    const double reward = input[3];
    const double old_q = input[4];
    if (alpha < 0.0 || alpha > 1.0 || gamma < 0.0 || gamma > 1.0 ||
        reward < -100.0 || reward > 100.0 || old_q < -100.0 || old_q > 100.0) return -1;

    size_t next_action_count;
    if (!exact_action_count(input[5], &next_action_count) ||
        input_length != 6 + next_action_count || input_length > MAX_VALID_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < next_action_count; ++index)
        if (input[6 + index] < -100.0 || input[6 + index] > 100.0) return -1;

    double max_q_next = 0.0;
    if (input[0] == 0.0 && next_action_count > 0) {
        max_q_next = input[6];
        for (size_t index = 1; index < next_action_count; ++index)
            if (input[6 + index] > max_q_next) max_q_next = input[6 + index];
    }

    const double old_weight = rounded_subtract(1.0, alpha);
    const double old_contribution = rounded_multiply(old_weight, old_q);
    const double discounted_next = rounded_multiply(gamma, max_q_next);
    const double target = rounded_add(reward, discounted_next);
    const double new_contribution = rounded_multiply(alpha, target);
    const double updated = rounded_add(old_contribution, new_contribution);
    if (!isfinite(updated)) return -1;

    const double staged[1] = { updated };
    if (output == NULL || output_capacity < 1) return -2;
    output[0] = staged[0];
    return 1;
}

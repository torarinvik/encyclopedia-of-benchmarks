/* One bounded Baum–Welch update for a discrete HMM. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define BW_MAX_STATES 4
#define BW_MAX_SYMBOLS 4
#define BW_MAX_TIME 8
#define BW_MAX_INPUT 48
#define BW_MAX_OUTPUT 36
#define BW_MIN_PROBABILITY 0.001
#define BW_ROW_TOLERANCE 1e-9

static int bw_exact_integer(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < (double)low || value > (double)high || trunc(value) != value)
        return 0;
    *decoded = (int)value;
    return 1;
}

static int bw_valid_row(const double *row, int count)
{
    double total = 0.0;
    for (int i = 0; i < count; ++i) {
        if (!isfinite(row[i]) || row[i] < BW_MIN_PROBABILITY || row[i] > 1.0) return 0;
        total += row[i];
    }
    return fabs(total - 1.0) <= BW_ROW_TOLERANCE;
}

int64_t baum_welch_reestimation(const double *input, size_t input_length,
                                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > BW_MAX_INPUT) return -1;
    int states, symbols, time_count;
    if (!bw_exact_integer(input[0], 2, BW_MAX_STATES, &states) ||
        !bw_exact_integer(input[1], 2, BW_MAX_SYMBOLS, &symbols) ||
        !bw_exact_integer(input[2], 1, BW_MAX_TIME, &time_count)) return -1;
    const size_t required = 3 + (size_t)states + (size_t)states * (size_t)states +
                            (size_t)states * (size_t)symbols + (size_t)time_count;
    if (input_length != required) return -1;

    size_t cursor = 3;
    double initial[BW_MAX_STATES] = {0};
    double transition[BW_MAX_STATES * BW_MAX_STATES] = {0};
    double emission[BW_MAX_STATES * BW_MAX_SYMBOLS] = {0};
    int observations[BW_MAX_TIME] = {0};
    for (int i = 0; i < states; ++i) initial[i] = input[cursor++];
    for (int i = 0; i < states * states; ++i) transition[i] = input[cursor++];
    for (int i = 0; i < states * symbols; ++i) emission[i] = input[cursor++];
    if (!bw_valid_row(initial, states)) return -1;
    for (int state = 0; state < states; ++state) {
        if (!bw_valid_row(transition + state * states, states) ||
            !bw_valid_row(emission + state * symbols, symbols)) return -1;
    }
    for (int time = 0; time < time_count; ++time) {
        if (!bw_exact_integer(input[cursor + (size_t)time], 0, symbols - 1, &observations[time])) return -1;
    }

    double alpha[BW_MAX_TIME * BW_MAX_STATES] = {0};
    double beta[BW_MAX_TIME * BW_MAX_STATES] = {0};
    double gamma[BW_MAX_TIME * BW_MAX_STATES] = {0};
    double staged[BW_MAX_OUTPUT] = {0};
    for (int state = 0; state < states; ++state)
        alpha[state] = initial[state] * emission[state * symbols + observations[0]];
    for (int time = 1; time < time_count; ++time) {
        for (int destination = 0; destination < states; ++destination) {
            double incoming = 0.0;
            for (int source = 0; source < states; ++source)
                incoming += alpha[(time - 1) * states + source] * transition[source * states + destination];
            alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]];
        }
    }
    double likelihood = 0.0;
    for (int state = 0; state < states; ++state)
        likelihood += alpha[(time_count - 1) * states + state];
    for (int state = 0; state < states; ++state) beta[(time_count - 1) * states + state] = 1.0;
    for (int time = time_count - 2; time >= 0; --time) {
        for (int source = 0; source < states; ++source) {
            double sum = 0.0;
            for (int destination = 0; destination < states; ++destination)
                sum += transition[source * states + destination]
                     * emission[destination * symbols + observations[time + 1]]
                     * beta[(time + 1) * states + destination];
            beta[time * states + source] = sum;
        }
    }
    for (int time = 0; time < time_count; ++time)
        for (int state = 0; state < states; ++state)
            gamma[time * states + state] = alpha[time * states + state] * beta[time * states + state] / likelihood;

    size_t output_count = (size_t)states + (size_t)states * (size_t)states + (size_t)states * (size_t)symbols;
    size_t out = 0;
    for (int state = 0; state < states; ++state) staged[out++] = gamma[state];
    if (time_count == 1) {
        for (int i = 0; i < states * states; ++i) staged[out++] = transition[i];
    } else {
        for (int source = 0; source < states; ++source) {
            double denominator = 0.0;
            for (int time = 0; time < time_count - 1; ++time)
                denominator += gamma[time * states + source];
            for (int destination = 0; destination < states; ++destination) {
                double count = 0.0;
                for (int time = 0; time < time_count - 1; ++time)
                    count += alpha[time * states + source] * transition[source * states + destination]
                           * emission[destination * symbols + observations[time + 1]]
                           * beta[(time + 1) * states + destination] / likelihood;
                staged[out++] = count / denominator;
            }
        }
    }
    for (int state = 0; state < states; ++state) {
        double denominator = 0.0;
        for (int time = 0; time < time_count; ++time) denominator += gamma[time * states + state];
        for (int symbol = 0; symbol < symbols; ++symbol) {
            double count = 0.0;
            for (int time = 0; time < time_count; ++time)
                if (observations[time] == symbol) count += gamma[time * states + state];
            staged[out++] = count / denominator;
        }
    }
    if (out != output_count) return -1;
    if (output == NULL || output_capacity < output_count) return -2;
    for (size_t i = 0; i < output_count; ++i) output[i] = staged[i];
    return (int64_t)output_count;
}

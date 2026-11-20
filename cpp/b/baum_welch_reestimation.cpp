// One bounded Baum–Welch update for a discrete HMM.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input = 48;
constexpr std::size_t max_output = 36;
constexpr double min_probability = 0.001;
constexpr double row_tolerance = 1e-9;

bool exact_integer(double value, int low, int high, int &decoded)
{
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}

bool valid_row(const double *row, int count)
{
    double total = 0.0;
    for (int i = 0; i < count; ++i) {
        if (!std::isfinite(row[i]) || row[i] < min_probability || row[i] > 1.0) return false;
        total += row[i];
    }
    return std::abs(total - 1.0) <= row_tolerance;
}
}

extern "C" std::int64_t baum_welch_reestimation(const double *input,
        std::size_t input_length, double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 3 || input_length > max_input) return -1;
    int states, symbols, time_count;
    if (!exact_integer(input[0], 2, 4, states) || !exact_integer(input[1], 2, 4, symbols) ||
        !exact_integer(input[2], 1, 8, time_count)) return -1;
    const auto required = std::size_t(3 + states + states * states + states * symbols + time_count);
    if (input_length != required) return -1;

    double initial[4]{};
    double transition[16]{};
    double emission[16]{};
    int observations[8]{};
    std::size_t cursor = 3;
    for (int i = 0; i < states; ++i) initial[i] = input[cursor++];
    for (int i = 0; i < states * states; ++i) transition[i] = input[cursor++];
    for (int i = 0; i < states * symbols; ++i) emission[i] = input[cursor++];
    if (!valid_row(initial, states)) return -1;
    for (int state = 0; state < states; ++state)
        if (!valid_row(transition + state * states, states) || !valid_row(emission + state * symbols, symbols)) return -1;
    for (int time = 0; time < time_count; ++time) {
        if (!exact_integer(input[cursor + time], 0, symbols - 1, observations[time])) return -1;
    }

    double alpha[32]{};
    double beta[32]{};
    double gamma[32]{};
    double staged[max_output]{};
    for (int state = 0; state < states; ++state) alpha[state] = initial[state] * emission[state * symbols + observations[0]];
    for (int time = 1; time < time_count; ++time) {
        for (int destination = 0; destination < states; ++destination) {
            double incoming = 0.0;
            for (int source = 0; source < states; ++source)
                incoming += alpha[(time - 1) * states + source] * transition[source * states + destination];
            alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]];
        }
    }
    double likelihood = 0.0;
    for (int state = 0; state < states; ++state) likelihood += alpha[(time_count - 1) * states + state];
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

    const auto output_count = std::size_t(states + states * states + states * symbols);
    std::size_t out = 0;
    for (int state = 0; state < states; ++state) staged[out++] = gamma[state];
    if (time_count == 1) {
        for (int i = 0; i < states * states; ++i) staged[out++] = transition[i];
    } else {
        for (int source = 0; source < states; ++source) {
            double denominator = 0.0;
            for (int time = 0; time < time_count - 1; ++time) denominator += gamma[time * states + source];
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
    if (output == nullptr || output_capacity < output_count) return -2;
    for (std::size_t i = 0; i < output_count; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_count);
}

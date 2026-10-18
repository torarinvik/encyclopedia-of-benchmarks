#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_observations = 12;
constexpr std::size_t max_parseable_length = 64;
constexpr std::size_t max_output_elements = 30;

void multiply_2x2(const double *left, const double *right, double *result) noexcept {
    for (std::size_t row = 0; row < 2; ++row) {
        for (std::size_t column = 0; column < 2; ++column) {
            double sum = 0.0;
            for (std::size_t inner = 0; inner < 2; ++inner)
                sum += left[row * 2 + inner] * right[inner * 2 + column];
            result[row * 2 + column] = sum;
        }
    }
}
}

extern "C" std::int64_t kalman_filter_r_two_state_simulation(
    const double *input, std::size_t input_length, double *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_length ||
        input_length > max_observations) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i]) || input[i] < -1000.0 || input[i] > 1000.0) return -1;
    }

    const double transition[4] = {1.0, 0.0, 1.0, 1.0};
    const double transition_t[4] = {1.0, 1.0, 0.0, 1.0};
    double state[2] = {input[0], 0.0};
    double covariance[4] = {1.0, 0.0, 0.0, 1.0};
    double trace[2 * max_observations] = {};
    double final_state_pred[2] = {0.0, 0.0};
    double final_covariance_pred[4] = {};

    for (std::size_t step = 0; step < input_length; ++step) {
        for (std::size_t i = 0; i < 2; ++i) {
            double sum = 0.0;
            for (std::size_t j = 0; j < 2; ++j) sum += transition[i * 2 + j] * state[j];
            final_state_pred[i] = sum;
        }

        double temp[4];
        multiply_2x2(transition, covariance, temp);
        multiply_2x2(temp, transition_t, final_covariance_pred);
        final_covariance_pred[0] += 0.0001;
        final_covariance_pred[3] += 0.0001;

        double h_pred[2];
        for (std::size_t column = 0; column < 2; ++column) {
            double sum = 0.0;
            sum += 1.0 * final_covariance_pred[column];
            sum += 0.0 * final_covariance_pred[2 + column];
            h_pred[column] = sum;
        }
        double innovation = 0.0;
        innovation += h_pred[0] * 1.0;
        innovation += h_pred[1] * 0.0;
        innovation += 0.1;

        double gain[2];
        const double inverse_innovation = 1.0 / innovation;
        for (std::size_t row = 0; row < 2; ++row) {
            double projected = 0.0;
            projected += final_covariance_pred[row * 2] * 1.0;
            projected += final_covariance_pred[row * 2 + 1] * 0.0;
            gain[row] = projected * inverse_innovation;
        }
        double h_state_pred = 0.0;
        h_state_pred += 1.0 * final_state_pred[0];
        h_state_pred += 0.0 * final_state_pred[1];
        const double residual = input[step] - h_state_pred;
        for (std::size_t row = 0; row < 2; ++row)
            state[row] = final_state_pred[row] + gain[row] * residual;
        trace[2 * step] = state[0];
        trace[2 * step + 1] = state[1];

        const double gain_observation[4] = {gain[0] * 1.0, gain[0] * 0.0,
                                            gain[1] * 1.0, gain[1] * 0.0};
        double update[4];
        for (std::size_t i = 0; i < 4; ++i) update[i] = 1.0 - gain_observation[i];
        multiply_2x2(update, final_covariance_pred, covariance);
    }

    double staged[max_output_elements] = {};
    std::size_t out = 0;
    for (std::size_t i = 0; i < 2 * input_length; ++i) staged[out++] = trace[i];
    staged[out++] = final_state_pred[0];
    staged[out++] = final_state_pred[1];
    staged[out++] = final_covariance_pred[0];
    staged[out++] = final_covariance_pred[2];
    staged[out++] = final_covariance_pred[1];
    staged[out++] = final_covariance_pred[3];
    const std::size_t result_length = out;
    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(result_length);
}

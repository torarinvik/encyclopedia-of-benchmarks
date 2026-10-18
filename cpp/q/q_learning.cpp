/* Perform one deterministic Q-learning update on a fresh bounded table. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_next_actions = 4;
constexpr std::size_t max_valid_input_length = 10;
constexpr std::size_t max_parseable_input_length = 11;

double rounded_subtract(double left, double right) noexcept {
    volatile double result = left - right;
    return result;
}

double rounded_multiply(double left, double right) noexcept {
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept {
    volatile double result = left + right;
    return result;
}

bool exact_action_count(double value, std::size_t& count) noexcept {
    if (!std::isfinite(value) || value < 0.0 || value > static_cast<double>(max_next_actions)) return false;
    const auto converted = static_cast<std::size_t>(value);
    if (static_cast<double>(converted) != value) return false;
    count = converted;
    return true;
}
}

extern "C" std::int64_t q_learning_update(const double* input, std::size_t input_length,
                                           double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 6 || input_length > max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index)
        if (!std::isfinite(input[index])) return -1;

    if (input[0] != 0.0 && input[0] != 1.0) return -1;
    const double alpha = input[1];
    const double gamma = input[2];
    const double reward = input[3];
    const double old_q = input[4];
    if (alpha < 0.0 || alpha > 1.0 || gamma < 0.0 || gamma > 1.0 ||
        reward < -100.0 || reward > 100.0 || old_q < -100.0 || old_q > 100.0) return -1;

    std::size_t next_action_count;
    if (!exact_action_count(input[5], next_action_count) ||
        input_length != 6 + next_action_count || input_length > max_valid_input_length) return -1;
    for (std::size_t index = 0; index < next_action_count; ++index)
        if (input[6 + index] < -100.0 || input[6 + index] > 100.0) return -1;

    double max_q_next = 0.0;
    if (input[0] == 0.0 && next_action_count > 0) {
        max_q_next = input[6];
        for (std::size_t index = 1; index < next_action_count; ++index)
            if (input[6 + index] > max_q_next) max_q_next = input[6 + index];
    }

    const double old_weight = rounded_subtract(1.0, alpha);
    const double old_contribution = rounded_multiply(old_weight, old_q);
    const double discounted_next = rounded_multiply(gamma, max_q_next);
    const double target = rounded_add(reward, discounted_next);
    const double new_contribution = rounded_multiply(alpha, target);
    const double updated = rounded_add(old_contribution, new_contribution);
    if (!std::isfinite(updated)) return -1;

    const double staged[1] = {updated};
    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = staged[0];
    return 1;
}

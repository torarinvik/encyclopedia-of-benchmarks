#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_steps = 256, max_parameters = 16;
constexpr double input_scale = 1'000'000'000.0, output_scale = 1'000'000.0;

double adam_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}
} // namespace

extern "C" std::int64_t adam(const std::int64_t *input, std::size_t length,
                              std::uint8_t *output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_input_length = 7 + max_parameters + max_steps * max_parameters;
    if (input == nullptr || length < 9 || length > max_input_length) return -1;
    const auto steps_value = input[0], parameter_count_value = input[1];
    const auto learning_rate_value = input[2], beta1_value = input[3], beta2_value = input[4];
    const auto epsilon_value = input[5], weight_decay_value = input[6];
    if (steps_value < 1 || steps_value > static_cast<std::int64_t>(max_steps) ||
        parameter_count_value < 1 || parameter_count_value > static_cast<std::int64_t>(max_parameters)) return -1;
    const auto steps = static_cast<std::size_t>(steps_value);
    const auto parameter_count = static_cast<std::size_t>(parameter_count_value);
    if (length != 7 + parameter_count + steps * parameter_count ||
        learning_rate_value < 1 || learning_rate_value > 1'000'000'000 ||
        beta1_value < 0 || beta1_value >= 1'000'000'000 || beta2_value < 0 || beta2_value >= 1'000'000'000 ||
        epsilon_value < 1 || epsilon_value > 10'000'000 || weight_decay_value < 0 || weight_decay_value > 100'000'000) return -1;
    for (std::size_t i = 0; i < parameter_count; ++i)
        if (input[7 + i] < -1'000'000'000'000'000LL || input[7 + i] > 1'000'000'000'000'000LL) return -1;
    const std::size_t gradient_start = 7 + parameter_count;
    for (std::size_t i = 0; i < steps * parameter_count; ++i)
        if (input[gradient_start + i] < -1'000'000'000'000LL || input[gradient_start + i] > 1'000'000'000'000LL) return -1;
    const std::size_t output_count = steps * parameter_count;
    if (output == nullptr || output_capacity < 8 * output_count) return -2;

    const double learning_rate = static_cast<double>(learning_rate_value) / input_scale;
    const double beta1 = static_cast<double>(beta1_value) / input_scale;
    const double beta2 = static_cast<double>(beta2_value) / input_scale;
    const double epsilon = static_cast<double>(epsilon_value) / input_scale;
    const double weight_decay = static_cast<double>(weight_decay_value) / input_scale;
    double parameters[max_parameters]{}, first_moment[max_parameters]{}, second_moment[max_parameters]{};
    for (std::size_t i = 0; i < parameter_count; ++i) parameters[i] = static_cast<double>(input[7 + i]) / input_scale;
    double beta1_power = 1.0, beta2_power = 1.0;
    for (std::size_t step = 0; step < steps; ++step) {
        beta1_power *= beta1;
        beta2_power *= beta2;
        for (std::size_t i = 0; i < parameter_count; ++i) {
            const double gradient = static_cast<double>(input[gradient_start + step * parameter_count + i]) / input_scale;
            first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient;
            second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient);
            const double corrected_first = first_moment[i] / (1.0 - beta1_power);
            const double corrected_second = second_moment[i] / (1.0 - beta2_power);
            const double updated = parameters[i] - learning_rate * corrected_first /
                (adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i];
            parameters[i] = updated;
            const auto bits = static_cast<std::uint64_t>(static_cast<std::int64_t>(updated * output_scale));
            const std::size_t output_index = step * parameter_count + i;
            for (std::size_t byte = 0; byte < 8; ++byte) output[8 * output_index + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
        }
    }
    return static_cast<std::int64_t>(output_count);
}

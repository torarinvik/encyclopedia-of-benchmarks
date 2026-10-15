#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_steps = 256, max_groups = 16;
constexpr double input_scale = 1'000'000'000.0, output_scale = 1'000'000.0;

double adagrad_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}
} // namespace

extern "C" std::int64_t adagrad(const std::int64_t *input, std::size_t length,
                                 std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 6 || length > 3 + 3 * max_steps) return -1;
    const auto steps_value = input[0], learning_rate_value = input[1], epsilon_value = input[2];
    if (steps_value < 1 || steps_value > static_cast<std::int64_t>(max_steps) ||
        length != 3 + 3 * static_cast<std::size_t>(steps_value) ||
        learning_rate_value < 1 || learning_rate_value > 1'000'000'000 ||
        epsilon_value < 1 || epsilon_value > 10'000'000) return -1;
    const auto steps = static_cast<std::size_t>(steps_value);
    for (std::size_t step = 0; step < steps; ++step) {
        const auto id = input[3 + 3 * step], parameter = input[4 + 3 * step], gradient = input[5 + 3 * step];
        if (id < 0 || id >= static_cast<std::int64_t>(max_groups) ||
            parameter < -1'000'000'000'000'000LL || parameter > 1'000'000'000'000'000LL ||
            gradient < -1'000'000'000'000LL || gradient > 1'000'000'000'000LL) return -1;
    }
    if (output == nullptr || output_capacity < 8 * steps) return -2;

    const double learning_rate = static_cast<double>(learning_rate_value) / input_scale;
    const double epsilon = static_cast<double>(epsilon_value) / input_scale;
    double accumulated[max_groups]{};
    for (std::size_t step = 0; step < steps; ++step) {
        const auto id = static_cast<std::size_t>(input[3 + 3 * step]);
        const double parameter = static_cast<double>(input[4 + 3 * step]) / input_scale;
        const double gradient = static_cast<double>(input[5 + 3 * step]) / input_scale;
        accumulated[id] += gradient * gradient;
        const double updated = parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient;
        const auto bits = static_cast<std::uint64_t>(static_cast<std::int64_t>(updated * output_scale));
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * step + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(steps);
}

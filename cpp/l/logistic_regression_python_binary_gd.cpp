#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

constexpr int MAX_SAMPLES = 32;
constexpr int MAX_FEATURES = 8;
constexpr double Q_SCALE = 1000000.0;

static void put_f64(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t logistic_regression_python_binary_gd(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4) return -1;
    auto mv = input[0], dv = input[1], epochs_value = input[2], alpha_q = input[3];
    if (mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES
            || epochs_value < 0 || epochs_value > 128 || alpha_q < 1 || alpha_q > 100000) return -1;
    int m = static_cast<int>(mv), d = static_cast<int>(dv), epochs = static_cast<int>(epochs_value);
    if (length != 4 + static_cast<std::size_t>(m) * static_cast<std::size_t>(d) + static_cast<std::size_t>(m)) return -1;
    std::size_t labels_offset = 4 + static_cast<std::size_t>(m) * static_cast<std::size_t>(d);
    for (std::size_t i = 0; i < static_cast<std::size_t>(m) * static_cast<std::size_t>(d); ++i)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;
    for (int sample = 0; sample < m; ++sample)
        if (input[labels_offset + static_cast<std::size_t>(sample)] != 0
                && input[labels_offset + static_cast<std::size_t>(sample)] != 1) return -1;
    std::size_t required = static_cast<std::size_t>(d) * 8;
    if (output == nullptr || capacity < required) return -2;

    double theta[MAX_FEATURES]{}, next_theta[MAX_FEATURES], errors[MAX_SAMPLES];
    double alpha = static_cast<double>(alpha_q) / Q_SCALE;
    for (int epoch = 0; epoch < epochs; ++epoch) {
        for (int sample = 0; sample < m; ++sample) {
            double score = 0.0;
            for (int feature = 0; feature < d; ++feature) {
                double x = static_cast<double>(input[4 + sample * d + feature]) / Q_SCALE;
                score += x * theta[feature];
            }
            double prediction = 1.0 / (1.0 + std::exp(-score));
            errors[sample] = prediction - static_cast<double>(input[labels_offset + static_cast<std::size_t>(sample)]);
        }
        for (int feature = 0; feature < d; ++feature) {
            double gradient = 0.0;
            for (int sample = 0; sample < m; ++sample) {
                double x = static_cast<double>(input[4 + sample * d + feature]) / Q_SCALE;
                gradient += x * errors[sample];
            }
            gradient /= static_cast<double>(m);
            next_theta[feature] = theta[feature] - alpha * gradient;
        }
        for (int feature = 0; feature < d; ++feature) theta[feature] = next_theta[feature];
    }
    for (int feature = 0; feature < d; ++feature) put_f64(output, static_cast<std::size_t>(feature) * 8, theta[feature]);
    return static_cast<std::int64_t>(required);
}

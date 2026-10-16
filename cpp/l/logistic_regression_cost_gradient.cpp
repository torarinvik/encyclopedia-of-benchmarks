#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

constexpr int MAX_SAMPLES = 64;
constexpr int MAX_FEATURES = 8;
constexpr double Q_SCALE = 1000000.0;

static void put_f64(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t logistic_regression_cost_gradient(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return -1;
    const auto m_value = input[0], d_value = input[1];
    if (m_value < 1 || m_value > MAX_SAMPLES || d_value < 1 || d_value > MAX_FEATURES) return -1;
    const std::size_t m = static_cast<std::size_t>(m_value), d = static_cast<std::size_t>(d_value);
    const std::size_t features_offset = 2, theta_offset = features_offset + m * d;
    const std::size_t labels_offset = theta_offset + d;
    if (length != labels_offset + m) return -1;
    for (std::size_t index = 0; index < m * d; ++index)
        if (input[features_offset + index] < -1000000 || input[features_offset + index] > 1000000) return -1;
    for (std::size_t feature = 0; feature < d; ++feature)
        if (input[theta_offset + feature] < -1000000 || input[theta_offset + feature] > 1000000) return -1;
    for (std::size_t sample = 0; sample < m; ++sample)
        if (input[labels_offset + sample] != 0 && input[labels_offset + sample] != 1) return -1;

    const std::size_t required = (d + 1) * 8;
    if (output == nullptr || capacity < required) return -2;
    double loss = 0.0, gradient[MAX_FEATURES]{};
    for (std::size_t sample = 0; sample < m; ++sample) {
        double score = 0.0;
        for (std::size_t feature = 0; feature < d; ++feature) {
            const double x = static_cast<double>(input[features_offset + sample * d + feature]) / Q_SCALE;
            const double theta = static_cast<double>(input[theta_offset + feature]) / Q_SCALE;
            score += x * theta;
        }
        const double probability = 1.0 / (1.0 + std::exp(-score));
        const double label = static_cast<double>(input[labels_offset + sample]);
        loss += -label * std::log(probability) - (1.0 - label) * std::log(1.0 - probability);
        const double error = probability - label;
        for (std::size_t feature = 0; feature < d; ++feature) {
            const double x = static_cast<double>(input[features_offset + sample * d + feature]) / Q_SCALE;
            gradient[feature] += error * x;
        }
    }
    put_f64(output, 0, loss / static_cast<double>(m));
    for (std::size_t feature = 0; feature < d; ++feature)
        put_f64(output, (feature + 1) * 8, gradient[feature] / static_cast<double>(m));
    return static_cast<std::int64_t>(required);
}

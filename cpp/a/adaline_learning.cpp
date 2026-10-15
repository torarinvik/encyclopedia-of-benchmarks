// Fixed-point projection of the pinned deterministic ADALINE update loop.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples = 32;
constexpr std::size_t max_features = 8;

void store_i32_le(std::int64_t value, std::uint8_t *output, std::size_t offset) {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t adaline_learning(const std::int64_t *input,
                                         std::size_t length,
                                         std::uint8_t *output,
                                         std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 5) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_samples) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_features) ||
        input[2] < 1 || input[3] < 1 || input[3] > 12 ||
        input[4] < 1 || input[4] > 500) return -1;

    const auto sample_count = static_cast<std::size_t>(input[0]);
    const auto feature_count = static_cast<std::size_t>(input[1]);
    const auto eta_numerator = input[2];
    const auto eta_shift = static_cast<unsigned>(input[3]);
    const auto max_iterations = static_cast<std::size_t>(input[4]);
    const std::int64_t scale = std::int64_t{1} << eta_shift;
    if (eta_numerator >= scale || length != 5 + sample_count * (feature_count + 1))
        return -1;

    for (std::size_t sample = 0; sample < sample_count; ++sample) {
        const auto row = 5 + sample * (feature_count + 1);
        for (std::size_t feature = 0; feature < feature_count; ++feature)
            if (input[row + feature] < -16 || input[row + feature] > 16) return -1;
        const auto label = input[row + feature_count];
        if (label != -1 && label != 1) return -1;
    }

    const auto bytes = 4 * (1 + feature_count + 1 + sample_count);
    if (output_capacity < bytes || output == nullptr) return -2;

    std::int64_t weights[max_features]{};
    for (std::size_t feature = 0; feature < feature_count; ++feature)
        weights[feature] = scale;
    std::int64_t bias = scale;
    std::size_t iterations = 0;
    for (; iterations < max_iterations; ++iterations) {
        std::size_t mistakes = 0;
        for (std::size_t sample = 0; sample < sample_count; ++sample) {
            const auto row = 5 + sample * (feature_count + 1);
            std::int64_t score = bias;
            for (std::size_t feature = 0; feature < feature_count; ++feature)
                score += input[row + feature] * weights[feature];
            const std::int64_t prediction = score > 0 ? 1 : -1;
            const auto error = input[row + feature_count] - prediction;
            if (error != 0) {
                ++mistakes;
                const auto correction = eta_numerator * error;
                for (std::size_t feature = 0; feature < feature_count; ++feature)
                    weights[feature] += correction * input[row + feature];
                bias += correction;
            }
        }
        if (mistakes == 0) {
            ++iterations;
            break;
        }
    }

    std::size_t position = 0;
    store_i32_le(static_cast<std::int64_t>(iterations), output, position); position += 4;
    for (std::size_t feature = 0; feature < feature_count; ++feature, position += 4)
        store_i32_le(weights[feature], output, position);
    store_i32_le(bias, output, position); position += 4;
    for (std::size_t sample = 0; sample < sample_count; ++sample) {
        const auto row = 5 + sample * (feature_count + 1);
        std::int64_t score = bias;
        for (std::size_t feature = 0; feature < feature_count; ++feature)
            score += input[row + feature] * weights[feature];
        store_i32_le(score > 0 ? 1 : -1, output, position);
        position += 4;
    }
    return static_cast<std::int64_t>(bytes);
}

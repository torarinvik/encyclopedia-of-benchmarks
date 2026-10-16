#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t SCALE = 1'000'000;
constexpr std::int64_t MAX_PAIRS = 64;
constexpr std::int64_t MAX_PARSED_PAIRS = 65;
constexpr std::int64_t MAX_SAMPLE = 1'000'000'000;
constexpr std::int64_t MAX_DELTA = 1'000'000'000;
constexpr std::size_t MAX_INPUT_LENGTH = 133;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double huber_loss(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t delta_value = values[0], true_count_value = values[1], pred_count_value = values[2];
    if (delta_value < 0 || delta_value > MAX_DELTA ||
        true_count_value < 0 || true_count_value > MAX_PARSED_PAIRS ||
        pred_count_value < 0 || pred_count_value > MAX_PARSED_PAIRS) return INVALID_RESULT;
    if (length != static_cast<std::size_t>(3 + true_count_value + pred_count_value) ||
        true_count_value != pred_count_value || pred_count_value == 0 ||
        true_count_value > MAX_PAIRS) return INVALID_RESULT;

    const std::size_t count = static_cast<std::size_t>(true_count_value);
    for (std::size_t index = 0; index < count * 2; ++index) {
        if (values[3 + index] < -MAX_SAMPLE || values[3 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }
    const double delta = static_cast<double>(delta_value) / static_cast<double>(SCALE);
    double total_loss = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double true_value = static_cast<double>(values[3 + index]) / static_cast<double>(SCALE);
        const double predicted_value = static_cast<double>(values[3 + count + index]) / static_cast<double>(SCALE);
        const double difference = true_value - predicted_value;
        const double residual = difference < 0.0 ? -difference : difference;
        if (residual <= delta) total_loss += 0.5 * (residual * residual);
        else total_loss += delta * residual - 0.5 * (delta * delta);
    }
    return total_loss / static_cast<double>(count);
}

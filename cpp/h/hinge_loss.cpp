#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 1 + 2 * MAX_COUNT;
constexpr double PREDICTION_SCALE = 1000000.0;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double hinge_loss(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_COUNT)) return INVALID_RESULT;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return INVALID_RESULT;

    double total = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t label = values[1 + index];
        const std::int64_t score_scaled = values[1 + count + index];
        if ((label != -1 && label != 1) || score_scaled < -1000000 || score_scaled > 1000000)
            return INVALID_RESULT;
        const double prediction = static_cast<double>(score_scaled) / PREDICTION_SCALE;
        const double loss = 1.0 - static_cast<double>(label) * prediction;
        if (loss > 0.0) total += loss;
    }
    return total / static_cast<double>(count);
}

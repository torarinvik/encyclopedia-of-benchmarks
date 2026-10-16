#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OBSERVATIONS = 64;
constexpr std::size_t MAX_FEATURES = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double linear_regression_cost(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (values[0] < 1 || values[0] > 64 || values[1] < 1 || values[1] > 16) return INVALID_RESULT;
    const std::size_t observations = static_cast<std::size_t>(values[0]);
    const std::size_t features = static_cast<std::size_t>(values[1]);
    const std::size_t matrix_length = observations * features;
    if (length != 2 + matrix_length + features + observations) return INVALID_RESULT;
    for (std::size_t index = 2; index < length; ++index) {
        if (values[index] < -1000 || values[index] > 1000) return INVALID_RESULT;
    }

    const std::size_t weights_start = 2 + matrix_length;
    const std::size_t targets_start = weights_start + features;
    double squared_error_sum = 0.0;
    for (std::size_t row = 0; row < observations; ++row) {
        double prediction = 0.0;
        const std::size_t row_start = 2 + row * features;
        for (std::size_t column = 0; column < features; ++column)
            prediction += static_cast<double>(values[row_start + column]) *
                          static_cast<double>(values[weights_start + column]);
        const double error = prediction - static_cast<double>(values[targets_start + row]);
        squared_error_sum += error * error;
    }
    return squared_error_sum / (2.0 * static_cast<double>(observations));
}

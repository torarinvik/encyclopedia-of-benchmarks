#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 64;
constexpr std::size_t kIterations = 100;
constexpr double kLearningRate = 0.01;
constexpr double kBeta = 0.9;
}

extern "C" std::int64_t momentum(const double *input, std::size_t length,
                                  double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length == 0 || length > kMaxLength) return -1;
    double values[kMaxLength];
    double velocity[kMaxLength]{};
    double gradient[kMaxLength];
    for (std::size_t index = 0; index < length; ++index) {
        if (!std::isfinite(input[index]) || input[index] < -1000000.0 || input[index] > 1000000.0) return -1;
        values[index] = input[index];
    }
    if (output == nullptr || output_capacity < length) return -2;

    for (std::size_t iteration = 0; iteration < kIterations; ++iteration) {
        for (std::size_t index = 0; index < length; ++index) gradient[index] = 2.0 * values[index];
        for (std::size_t index = 0; index < length; ++index) {
            velocity[index] = kBeta * velocity[index] + gradient[index];
            values[index] -= kLearningRate * velocity[index];
        }
    }
    for (std::size_t index = 0; index < length; ++index) output[index] = values[index];
    return static_cast<std::int64_t>(length);
}

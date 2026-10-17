/* Bounded float32 PID steps adapted from the pinned C pid_step function. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxInputLength = 64;
constexpr std::size_t kMaxErrors = 60;
}

extern "C" std::int64_t pid(const double *input, std::size_t length,
                            double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 5 || length > kMaxInputLength) return -1;
    const std::size_t error_count = length - 4;
    const double kp64 = input[0];
    const double ki64 = input[1];
    const double kd64 = input[2];
    const double dt64 = input[3];
    if (!std::isfinite(kp64) || kp64 < -1.0 || kp64 > 1.0
            || !std::isfinite(ki64) || ki64 < -1.0 || ki64 > 1.0
            || !std::isfinite(kd64) || kd64 < -1.0 || kd64 > 1.0
            || !std::isfinite(dt64) || (dt64 != 0.0 && (dt64 < 0.01 || dt64 > 1.0))
            || error_count < 1 || error_count > kMaxErrors) return -1;

    float errors[kMaxErrors];
    for (std::size_t index = 0; index < error_count; ++index) {
        const double value = input[4 + index];
        if (!std::isfinite(value) || value < -1.0 || value > 1.0) return -1;
        errors[index] = static_cast<float>(value);
    }
    if (output == nullptr || output_capacity < error_count) return -2;

    const float kp = static_cast<float>(kp64);
    const float ki = static_cast<float>(ki64);
    const float kd = static_cast<float>(kd64);
    const float dt = static_cast<float>(dt64);
    float integral = 0.0F;
    float last_error = 0.0F;
    for (std::size_t index = 0; index < error_count; ++index) {
        const float error = errors[index];
        const float proportional = error * kp;
        float integral_step = error * dt;
        integral_step = integral_step * ki;
        integral = integral + integral_step;
        float derivative = 0.0F;
        if (dt != 0.0F) {
            const float difference = error - last_error;
            const float rate = difference / dt;
            derivative = rate * kd;
        }
        last_error = error;
        const float partial = proportional + integral;
        const float result = partial + derivative;
        output[index] = static_cast<double>(result);
    }
    return static_cast<std::int64_t>(error_count);
}

/* Bounded float32 PID steps adapted from the pinned C pid_step function. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { PID_MAX_INPUT_LENGTH = 64, PID_MAX_ERRORS = 60 };

int64_t pid(const double *input, size_t length, double *output,
            size_t output_capacity)
{
    if (input == NULL || length < 5 || length > PID_MAX_INPUT_LENGTH) return -1;
    const size_t error_count = length - 4;
    const double kp64 = input[0];
    const double ki64 = input[1];
    const double kd64 = input[2];
    const double dt64 = input[3];
    if (!isfinite(kp64) || kp64 < -1.0 || kp64 > 1.0
            || !isfinite(ki64) || ki64 < -1.0 || ki64 > 1.0
            || !isfinite(kd64) || kd64 < -1.0 || kd64 > 1.0
            || !isfinite(dt64) || (dt64 != 0.0 && (dt64 < 0.01 || dt64 > 1.0))
            || error_count < 1 || error_count > PID_MAX_ERRORS) return -1;

    float errors[PID_MAX_ERRORS];
    for (size_t index = 0; index < error_count; ++index) {
        const double value = input[4 + index];
        if (!isfinite(value) || value < -1.0 || value > 1.0) return -1;
        errors[index] = (float)value;
    }
    if (output == NULL || output_capacity < error_count) return -2;

    const float kp = (float)kp64;
    const float ki = (float)ki64;
    const float kd = (float)kd64;
    const float dt = (float)dt64;
    float integral = 0.0f;
    float last_error = 0.0f;
    for (size_t index = 0; index < error_count; ++index) {
        const float error = errors[index];
        const float proportional = error * kp;
        float integral_step = error * dt;
        integral_step = integral_step * ki;
        integral = integral + integral_step;
        float derivative = 0.0f;
        if (dt != 0.0f) {
            const float difference = error - last_error;
            const float rate = difference / dt;
            derivative = rate * kd;
        }
        last_error = error;
        const float partial = proportional + integral;
        const float result = partial + derivative;
        output[index] = (double)result;
    }
    return (int64_t)error_count;
}

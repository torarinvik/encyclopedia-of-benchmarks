// Selected component of single-phase complex apparent power.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.14159265358979323846; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double apparent_power(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 5) return INVALID_RESULT;
    const auto component = values[0];
    const auto voltage = values[1];
    const auto current = values[2];
    const auto voltage_angle = values[3];
    const auto current_angle = values[4];
    if ((component != 0 && component != 1) || voltage < 0 || voltage > 1000 ||
        current < 0 || current > 1000 || voltage_angle < -360 || voltage_angle > 360 ||
        current_angle < -360 || current_angle > 360) return INVALID_RESULT;
    const double voltage_radians = static_cast<double>(voltage_angle) * (PI / 180.0);
    const double current_radians = static_cast<double>(current_angle) * (PI / 180.0);
    const double voltage_real = static_cast<double>(voltage) * std::cos(voltage_radians);
    const double voltage_imag = static_cast<double>(voltage) * std::sin(voltage_radians);
    const double current_real = static_cast<double>(current) * std::cos(current_radians);
    const double current_imag = static_cast<double>(current) * std::sin(current_radians);
    const double real = voltage_real * current_real - voltage_imag * current_imag;
    const double imag = voltage_real * current_imag + voltage_imag * current_real;
    return component == 0 ? real : imag;
}

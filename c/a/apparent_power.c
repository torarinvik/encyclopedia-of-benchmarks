/* Selected component of single-phase complex apparent power. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define INVALID_RESULT (-1.0e300)

double apparent_power(const int64_t *values, size_t length)
{
    if (values == NULL || length != 5) return INVALID_RESULT;
    const int64_t component = values[0];
    const int64_t voltage = values[1];
    const int64_t current = values[2];
    const int64_t voltage_angle = values[3];
    const int64_t current_angle = values[4];
    if ((component != 0 && component != 1) || voltage < 0 || voltage > 1000 ||
        current < 0 || current > 1000 || voltage_angle < -360 || voltage_angle > 360 ||
        current_angle < -360 || current_angle > 360) return INVALID_RESULT;
    const double voltage_radians = (double)voltage_angle * (PI / 180.0);
    const double current_radians = (double)current_angle * (PI / 180.0);
    const double voltage_real = (double)voltage * cos(voltage_radians);
    const double voltage_imag = (double)voltage * sin(voltage_radians);
    const double current_real = (double)current * cos(current_radians);
    const double current_imag = (double)current * sin(current_radians);
    const double real = voltage_real * current_real - voltage_imag * current_imag;
    const double imag = voltage_real * current_imag + voltage_imag * current_real;
    return component == 0 ? real : imag;
}

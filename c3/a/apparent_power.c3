module apparent_power;

extern fn double cos(double value);
extern fn double sin(double value);
const double PI = 3.14159265358979323846;
const double INVALID_RESULT = -1.0e300;

fn double apparent_power(long* values, usz length) @export("apparent_power") {
    if (values == null || length != 5) return INVALID_RESULT;
    long component = values[0];
    long voltage = values[1];
    long current = values[2];
    long voltage_angle = values[3];
    long current_angle = values[4];
    if ((component != 0 && component != 1) || voltage < 0 || voltage > 1000 ||
        current < 0 || current > 1000 || voltage_angle < -360 || voltage_angle > 360 ||
        current_angle < -360 || current_angle > 360) return INVALID_RESULT;
    double voltage_radians = (double)voltage_angle * (PI / 180.0);
    double current_radians = (double)current_angle * (PI / 180.0);
    double voltage_real = (double)voltage * cos(voltage_radians);
    double voltage_imag = (double)voltage * sin(voltage_radians);
    double current_real = (double)current * cos(current_radians);
    double current_imag = (double)current * sin(current_radians);
    double real = voltage_real * current_real - voltage_imag * current_imag;
    double imag = voltage_real * current_imag + voltage_imag * current_real;
    return component == 0 ? real : imag;
}

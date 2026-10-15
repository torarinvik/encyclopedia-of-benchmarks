/// Selected component of single-phase complex apparent power.
export fn apparent_power(values: [*]const i64, length: usize) f64 {
    if (length != 5) return -1.0e300;
    const component = values[0];
    const voltage = values[1];
    const current = values[2];
    const voltage_angle = values[3];
    const current_angle = values[4];
    if ((component != 0 and component != 1) or voltage < 0 or voltage > 1000 or
        current < 0 or current > 1000 or voltage_angle < -360 or voltage_angle > 360 or
        current_angle < -360 or current_angle > 360) return -1.0e300;
    const pi = 3.14159265358979323846;
    const voltage_radians = @as(f64, @floatFromInt(voltage_angle)) * (pi / 180.0);
    const current_radians = @as(f64, @floatFromInt(current_angle)) * (pi / 180.0);
    const voltage_real = @as(f64, @floatFromInt(voltage)) * @cos(voltage_radians);
    const voltage_imag = @as(f64, @floatFromInt(voltage)) * @sin(voltage_radians);
    const current_real = @as(f64, @floatFromInt(current)) * @cos(current_radians);
    const current_imag = @as(f64, @floatFromInt(current)) * @sin(current_radians);
    const real = voltage_real * current_real - voltage_imag * current_imag;
    const imag = voltage_real * current_imag + voltage_imag * current_real;
    return if (component == 0) real else imag;
}

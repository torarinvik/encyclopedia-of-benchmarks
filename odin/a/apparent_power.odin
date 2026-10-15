package apparent_power

import "core:c"
import "core:math"

@(export)
apparent_power :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 5 do return -1.0e300
    component := values[0]
    voltage := values[1]
    current := values[2]
    voltage_angle := values[3]
    current_angle := values[4]
    if (component != 0 && component != 1) || voltage < 0 || voltage > 1000 ||
        current < 0 || current > 1000 || voltage_angle < -360 || voltage_angle > 360 ||
        current_angle < -360 || current_angle > 360 do return -1.0e300
    pi: f64 = 3.14159265358979323846
    voltage_radians := f64(voltage_angle) * (pi / 180.0)
    current_radians := f64(current_angle) * (pi / 180.0)
    voltage_real := f64(voltage) * math.cos(voltage_radians)
    voltage_imag := f64(voltage) * math.sin(voltage_radians)
    current_real := f64(current) * math.cos(current_radians)
    current_imag := f64(current) * math.sin(current_radians)
    real := voltage_real * current_real - voltage_imag * current_imag
    imag := voltage_real * current_imag + voltage_imag * current_real
    if component == 0 do return real
    return imag
}

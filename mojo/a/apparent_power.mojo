from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import cos, sin

@export("apparent_power")
fn apparent_power(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5:
        return -1.0e300
    let component = values[0]
    let voltage = values[1]
    let current = values[2]
    let voltage_angle = values[3]
    let current_angle = values[4]
    if (component != 0 and component != 1) or voltage < 0 or voltage > 1000 or current < 0 or current > 1000 or voltage_angle < -360 or voltage_angle > 360 or current_angle < -360 or current_angle > 360:
        return -1.0e300
    let pi = 3.14159265358979323846
    let vr = Float64(voltage_angle) * (pi / 180.0)
    let cr = Float64(current_angle) * (pi / 180.0)
    let voltage_real = Float64(voltage) * cos(vr)
    let voltage_imag = Float64(voltage) * sin(vr)
    let current_real = Float64(current) * cos(cr)
    let current_imag = Float64(current) * sin(cr)
    let real = voltage_real * current_real - voltage_imag * current_imag
    let imag = voltage_real * current_imag + voltage_imag * current_real
    if component == 0:
        return real
    return imag

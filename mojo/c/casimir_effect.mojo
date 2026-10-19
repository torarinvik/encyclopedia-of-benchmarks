from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import pow

@export("casimir_effect")
fn casimir_effect(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let force_units = values[0]
    let area_units = values[1]
    let distance_units = values[2]
    if force_units < 0 or force_units > 1000000 or area_units < 0 or area_units > 1000000 or distance_units < 0 or distance_units > 1000000: return -1.0e300
    var zero_count: Int64 = 0
    if force_units == 0: zero_count += 1
    if area_units == 0: zero_count += 1
    if distance_units == 0: zero_count += 1
    if zero_count != 1: return -1.0e300
    let force = Float64(force_units) * 1.0e-12
    let area = Float64(area_units) * 1.0e-6
    let distance = Float64(distance_units) * 1.0e-6
    let numerator_constant = 1.054571817e-34 * 3.0e8 * pow(3.14159265358979323846, 2.0)
    if force_units == 0: return (numerator_constant * area) / (240.0 * pow(distance, 4.0))
    if area_units == 0: return (240.0 * force * pow(distance, 4.0)) / numerator_constant
    return pow((numerator_constant * area) / (240.0 * force), 0.25)

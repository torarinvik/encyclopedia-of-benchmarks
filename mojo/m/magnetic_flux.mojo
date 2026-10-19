from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import cos, floor

@export("magnetic_flux")
fn magnetic_flux(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 3: return -1.0e300
    let field = v[0]; let area = v[1]; let angle = v[2]
    if field < 0 or field > 10000 or area < 0 or area > 10000 or (angle != 0 and angle != 60 and angle != 90 and angle != 120 and angle != 180): return -1.0e300
    let radians = Float64(angle) * (3.14159265358979323846 / 180.0)
    let flux = Float64(field) * Float64(area) * cos(radians)
    let scaled = flux * 10.0
    let rounded = floor(scaled + 0.5) if scaled >= 0.0 else -floor(-scaled + 0.5)
    return rounded / 10.0

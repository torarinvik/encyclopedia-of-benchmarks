from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("mass_energy_equivalence")
fn mass_energy_equivalence(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 2: return -1.0e300
    let op = v[0]; let value = v[1]
    if (op != 0 and op != 1) or value < 0 or value > 1_000_000_000: return -1.0e300
    let c = 299792458.0; let c2 = c * c
    return Float64(value) * c2 if op == 0 else Float64(value) / c2

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("check_polygon")
fn check_polygon(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 256: return -1
    var total: Int64 = 0
    var largest: Int64 = 0
    for i in range(length):
        let side = values[i]
        if side <= 0 or side > 1000000000: return -1
        total += side
        if side > largest: largest = side
    return 1 if largest < total - largest else 0

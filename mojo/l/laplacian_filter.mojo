from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("laplacian_filter")
fn laplacian_filter(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 9: return -1.0e300
    for i in range(9):
        if v[i] < 0 or v[i] > 255: return -1.0e300
    return Float64(4 * v[4] - v[1] - v[3] - v[5] - v[7])

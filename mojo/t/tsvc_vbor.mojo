from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_vbor")
fn tsvc_vbor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 769: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 128 or length != c_size_t(1 + 6 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 6 * n):
        if input[i] < 0 or input[i] > 2: return -1
    var checksum: Int64 = 0
    for i in range(n):
        let a = input[1 + i]
        let b = input[1 + n + i]
        let c = input[1 + 2 * n + i]
        let d = input[1 + 3 * n + i]
        let e = input[1 + 4 * n + i]
        let f = input[1 + 5 * n + i]
        let a1 = a * b * c + a * b * d + a * b * e + a * b * f + a * c * d + a * c * e + a * c * f + a * d * e + a * d * f + a * e * f
        let b1 = b * c * d + b * c * e + b * c * f + b * d * e + b * d * f + b * e * f
        let c1 = c * d * e + c * d * f + c * e * f
        let d1 = d * e * f
        checksum += a1 * b1 * c1 * d1
    return checksum

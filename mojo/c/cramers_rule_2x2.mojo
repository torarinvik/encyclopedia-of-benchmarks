from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cramers_rule_2x2")
fn cramers_rule_2x2(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6: return -1
    for i in range(6):
        if values[i] < -1000000 or values[i] > 1000000: return -1
    let a = values[0]
    let b = values[1]
    let c = values[2]
    let d = values[3]
    let e = values[4]
    let f = values[5]
    let det = a * e - d * b
    if det == 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let x = Float64(c * e - f * b) / Float64(det)
    let y = Float64(a * f - d * c) / Float64(det)
    let xb = bitcast[UInt64](x)
    let yb = bitcast[UInt64](y)
    for i in range(8):
        output[i] = UInt8((xb >> (8 * i)) & 255)
        output[8 + i] = UInt8((yb >> (8 * i)) & 255)
    return 2

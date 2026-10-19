from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sqrt_10005() -> Float64:
    var root: Float64 = 100.0
    for _ in range(8): root = 0.5 * (root + 10005.0 / root)
    return root

@export("chudnovsky_algorithm")
fn chudnovsky_algorithm(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1 or values[0] < 1 or values[0] > 12: return -1
    let precision = values[0]
    let output_length = 0 if precision == 1 else precision
    if capacity < output_length or (output_length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    if precision == 1: return 0
    let pi = (426880.0 * sqrt_10005()) / 13591409.0
    var fraction = pi - 3.0
    var staged = InlineArray[UInt8, 12](0)
    staged[0] = 51
    staged[1] = 46
    for digit in range(precision - 2):
        fraction *= 10.0
        let next_digit = Int64(fraction)
        staged[2 + digit] = UInt8(48 + next_digit)
        fraction -= Float64(next_digit)
    for i in range(output_length): output[i] = staged[i]
    return output_length

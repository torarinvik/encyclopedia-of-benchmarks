# Independent bounded LAME transform; GPL notice is retained in the package.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_lame_mid_side")
fn cbench_lame_mid_side(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let count_value = input[0]
    if not isfinite(count_value) or count_value < 1.0 or count_value > 32.0: return -1
    let count = Int(count_value)
    if Float64(count) != count_value or length != c_size_t(1 + 2 * count): return -1
    for i in range(2 * count):
        let value = input[1+i]
        if not isfinite(value) or value < -16.0 or value > 16.0: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(2 * count): return -2
    let factor = Float64(1.4142135623730951) * Float64(0.5)
    var staged = List[Float64](capacity=2 * count)
    for i in range(count):
        let left = input[1+i]
        let right = input[1+count+i]
        staged.append((left + right) * factor)
        staged.append((left - right) * factor)
    for i in range(2 * count): output[i] = staged[i]
    return Int64(2 * count)

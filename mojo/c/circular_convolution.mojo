from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("circular_convolution")
fn circular_convolution(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    let a_length = values[0]
    let b_length = values[1]
    if a_length < 1 or a_length > 8 or b_length < 1 or b_length > 8 or length != 2 + a_length + b_length: return -1
    for i in range(a_length + b_length):
        if values[2 + i] < -2 or values[2 + i] > 2: return -1
    let n = a_length if a_length > b_length else b_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < n: return -2
    var staged = InlineArray[UInt8, 8](0)
    for k in range(n):
        var sum: Int64 = 0
        for i in range(n):
            let b_index = (k + n - i) % n
            let a_value = values[2 + i] if i < a_length else 0
            let b_value = values[2 + a_length + b_index] if b_index < b_length else 0
            sum += a_value * b_value
        staged[k] = UInt8(sum + 256) if sum < 0 else UInt8(sum)
    for i in range(n): output[i] = staged[i]
    return n

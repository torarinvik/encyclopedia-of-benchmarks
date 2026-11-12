from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_LENGTH = 256
const MAX_ABS_VALUE = 1.0e100

@export("kahan_summation")
fn kahan_summation(values: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Float64, ImmutAnyOrigin]() or length > MAX_LENGTH:
        return -1
    for index in range(length):
        let value = values[index]
        if value != value or value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE:
            return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1:
        return -2

    var sum: Float64 = 0.0
    var correction: Float64 = 0.0
    for index in range(length):
        let adjusted = values[index] - correction
        let next = sum + adjusted
        correction = (next - sum) - adjusted
        sum = next
    output[0] = sum
    return 1

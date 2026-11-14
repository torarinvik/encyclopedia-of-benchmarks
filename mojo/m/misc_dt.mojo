from std.ffi import c_size_t
from std.math import cos, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("misc_dt")
fn misc_dt(
    input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 2:
        return -1
    let iteration_value = input[0]
    let size_value = input[1]
    if not isfinite(iteration_value) or not isfinite(size_value) or iteration_value < 1.0 or iteration_value > 128.0 or size_value < 1.0 or size_value > 64.0:
        return -1
    let iterations = Int(iteration_value)
    let size = Int(size_value)
    if Float64(iterations) != iteration_value or Float64(size) != size_value:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(size):
        return -2
    var numerator = InlineArray[Float64, 64](fill=0.0)
    var denominator = InlineArray[Float64, 64](fill=0.0)
    for i in range(size):
        let cosine = cos(Float32(size - i))
        let sine = sin(Float32(i))
        numerator[i] = 1.0000001 * Float64(cosine)
        denominator[i] = 1.0 + 1e-10 * Float64(sine)
    for _ in range(iterations):
        for i in range(size):
            numerator[i] /= denominator[i]
    for i in range(size):
        output[i] = numerator[i]
    return Int64(size)

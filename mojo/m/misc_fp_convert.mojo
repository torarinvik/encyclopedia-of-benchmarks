from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("misc_fp_convert")
fn misc_fp_convert(
    input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1:
        return -1
    let requested = input[0]
    if not isfinite(requested) or requested < 1.0 or requested > 256.0:
        return -1
    let iterations = Int(requested)
    if Float64(iterations) != requested:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1:
        return -2
    var x = InlineArray[Float32, 2048](fill=0.0)
    var y = InlineArray[Float32, 2048](fill=0.0)
    var a: Float32 = 0.0
    var b: Float32 = 1.0
    var total: Float64 = 0.0
    for iteration in range(iterations):
        if iteration % 10 == 0:
            a += Float32(0.1)
            b += Float32(0.2)
        else:
            a = 0.0
            b = 1.0
        for i in range(2048):
            x[i] = a + Float32(i)
            y[i] = b + Float32(i)
        var dot: Float64 = 0.0
        for i in range(2048):
            dot += Float64(x[i]) * Float64(y[i])
        total += dot
    output[0] = total
    return 1

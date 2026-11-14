from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("matmul_f64_4x4")
fn matmul_f64_4x4(
    input: UnsafePointer[Float64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 1:
        return -1
    let requested = input[0]
    if not isfinite(requested) or requested < 1.0 or requested > 10000.0:
        return -1
    let iterations = Int(requested)
    if Float64(iterations) != requested:
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 16:
        return -2

    var a = InlineArray[Float64, 16](fill=0.0)
    a[0]=4.5; a[1]=1.3; a[2]=6.0; a[3]=4.1
    a[4]=2.5; a[5]=7.2; a[6]=7.7; a[7]=1.7
    a[8]=6.7; a[9]=1.3; a[10]=9.4; a[11]=1.3
    a[12]=1.1; a[13]=2.2; a[14]=3.0; a[15]=2.1
    var b = InlineArray[Float64, 16](fill=0.0)
    b[0]=1.0; b[1]=7.9; b[2]=5.1; b[3]=3.4
    b[4]=6.6; b[5]=2.8; b[6]=5.4; b[7]=9.2
    b[8]=5.0; b[9]=4.1; b[10]=4.1; b[11]=9.9
    b[12]=8.4; b[13]=3.7; b[14]=9.5; b[15]=6.4
    var result = InlineArray[Float64, 16](fill=0.0)
    for _ in range(iterations):
        for row in range(4):
            for column in range(4):
                var sum = a[4 * row] * b[column]
                sum += a[4 * row + 1] * b[4 + column]
                sum += a[4 * row + 2] * b[8 + column]
                sum += a[4 * row + 3] * b[12 + column]
                result[4 * row + column] = sum
    for i in range(16):
        output[i] = result[i]
    return 16

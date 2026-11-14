# PolyBench MVT bounded profile; see benchmarks/m/mvt/LICENSE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("mvt")
fn mvt(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1e300
    let dimension = input[0]
    if dimension < 1 or dimension > 64:
        return -1e300
    let n = Int(dimension)
    let divisor = Float64(n)
    var matrix = InlineArray[Float64, 4096](fill=0.0)
    var x1 = InlineArray[Float64, 64](fill=0.0)
    var x2 = InlineArray[Float64, 64](fill=0.0)
    var y1 = InlineArray[Float64, 64](fill=0.0)
    var y2 = InlineArray[Float64, 64](fill=0.0)
    for i in range(n):
        x1[i] = Float64(i % n) / divisor
        x2[i] = Float64((i + 1) % n) / divisor
        y1[i] = Float64((i + 3) % n) / divisor
        y2[i] = Float64((i + 4) % n) / divisor
        for j in range(n):
            matrix[i * n + j] = Float64((i * j) % n) / divisor
    for i in range(n):
        for j in range(n):
            x1[i] += matrix[i * n + j] * y1[j]
    for i in range(n):
        for j in range(n):
            x2[i] += matrix[j * n + i] * y2[j]
    var checksum: Float64 = 0.0
    for i in range(n):
        checksum += x1[i]
    for i in range(n):
        checksum += x2[i]
    return checksum

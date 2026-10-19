from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import fabs, sqrt

@export("cholesky_decomposition")
fn cholesky_decomposition(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or values[0] < 1 or values[0] > 6: return -1
    let n = values[0]
    if length != 1 + n * n: return -1
    var matrix = InlineArray[Float64, 36](0.0)
    var lower = InlineArray[Float64, 36](0.0)
    for i in range(n * n):
        let scaled = values[i + 1]
        if scaled < -1000000000 or scaled > 1000000000: return -1
        matrix[i] = Float64(scaled) / 1000000.0
    for row in range(n):
        for col in range(n):
            let left = matrix[row * n + col]
            let right = matrix[col * n + row]
            if fabs(left - right) > 1.0e-8 + 1.0e-5 * fabs(right): return -1
    for row in range(n):
        for col in range(row + 1):
            var sum: Float64 = 0.0
            for index in range(col): sum += lower[row * n + index] * lower[col * n + index]
            let residual = matrix[row * n + col] - sum
            if row == col:
                if residual <= 0.0: return -1
                lower[row * n + col] = sqrt(residual)
            else:
                lower[row * n + col] = residual / lower[col * n + col]
    let output_bytes = n * n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < output_bytes: return -2
    var staged = InlineArray[UInt8, 288](0)
    for i in range(n * n):
        let bits = bitcast[UInt64](lower[i])
        for byte in range(8): staged[i * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    for i in range(output_bytes): output[i] = staged[i]
    return output_bytes

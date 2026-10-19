from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("conjugate_gradient")
fn conjugate_gradient(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or values[0] < 1 or values[0] > 8: return -1
    let n = values[0]
    if length != 1 + n * n + n: return -1
    let vector_offset = 1 + n * n
    for i in range(n * n + n):
        if values[1 + i] < -1000000000 or values[1 + i] > 1000000000: return -1
    var matrix = InlineArray[Float64, 64](0.0)
    var rhs = InlineArray[Float64, 8](0.0)
    var solution = InlineArray[Float64, 8](0.0)
    var residual = InlineArray[Float64, 8](0.0)
    var direction = InlineArray[Float64, 8](0.0)
    var product = InlineArray[Float64, 8](0.0)
    for row in range(n):
        let diagonal = values[1 + row * n + row]
        if diagonal <= 0: return -1
        var off_sum: Int64 = 0
        for col in range(n):
            let entry = values[1 + row * n + col]
            if entry != values[1 + col * n + row]: return -1
            if col != row: off_sum += entry if entry >= 0 else -entry
            matrix[row * n + col] = Float64(entry) / 1000000.0
        if diagonal <= off_sum: return -1
        rhs[row] = Float64(values[vector_offset + row]) / 1000000.0
        residual[row] = rhs[row]
        direction[row] = rhs[row]
    let output_bytes = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < output_bytes: return -2
    var residual_squared: Float64 = 0.0
    for i in range(n): residual_squared += residual[i] * residual[i]
    var iteration: Int64 = 0
    while iteration < 1000 and residual_squared > 1.0e-20:
        for row in range(n):
            product[row] = 0.0
            for col in range(n): product[row] += matrix[row * n + col] * direction[col]
        var denominator: Float64 = 0.0
        for i in range(n): denominator += direction[i] * product[i]
        if not (denominator > 0.0) or not isfinite(denominator): return -1
        let alpha = residual_squared / denominator
        for i in range(n):
            solution[i] += alpha * direction[i]
            residual[i] -= alpha * product[i]
        var next_squared: Float64 = 0.0
        for i in range(n): next_squared += residual[i] * residual[i]
        if next_squared <= 1.0e-20:
            residual_squared = next_squared
            break
        let beta = next_squared / residual_squared
        for i in range(n): direction[i] = residual[i] + beta * direction[i]
        residual_squared = next_squared
        iteration += 1
    for i in range(n):
        if not isfinite(solution[i]): return -1
    for i in range(n):
        let bits = bitcast[UInt64](solution[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return output_bytes

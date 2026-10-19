from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("chebyshev_iteration")
fn chebyshev_iteration(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or values[0] < 1 or values[0] > 8: return -1
    let n = values[0]
    if length != 1 + n * n + 2 * n + 4: return -1
    let matrix_end = 1 + n * n
    let vector_end = matrix_end + 2 * n
    var matrix = InlineArray[Float64, 64](0.0)
    var b = InlineArray[Float64, 8](0.0)
    var x = InlineArray[Float64, 8](0.0)
    var residual = InlineArray[Float64, 8](0.0)
    var direction = InlineArray[Float64, 8](0.0)
    for i in range(n * n):
        let value = values[1 + i]
        if value < -1000000000 or value > 1000000000: return -1
        matrix[i] = Float64(value) / 1000000.0
    for i in range(n):
        let rhs = values[matrix_end + i]
        let guess = values[matrix_end + n + i]
        if rhs < -1000000000 or rhs > 1000000000 or guess < -1000000000 or guess > 1000000000: return -1
        b[i] = Float64(rhs) / 1000000.0
        x[i] = Float64(guess) / 1000000.0
    let min_micro = values[vector_end]
    let max_micro = values[vector_end + 1]
    let iteration_count = values[vector_end + 2]
    let tolerance_micro = values[vector_end + 3]
    if min_micro < 1 or max_micro <= min_micro or max_micro > 1000000000 or iteration_count < 1 or iteration_count > 1000 or tolerance_micro < 1 or tolerance_micro > 1000000000: return -1
    let min_eigenvalue = Float64(min_micro) / 1000000.0
    let max_eigenvalue = Float64(max_micro) / 1000000.0
    let tolerance = Float64(tolerance_micro) / 1000000.0
    let output_bytes = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < output_bytes: return -2
    for row in range(n):
        var product: Float64 = 0.0
        for col in range(n): product += matrix[row * n + col] * x[col]
        residual[row] = b[row] - product
    let d = (max_eigenvalue + min_eigenvalue) / 2.0
    let c = (max_eigenvalue - min_eigenvalue) / 2.0
    var alpha: Float64 = 0.0
    var alpha_previous: Float64 = 0.0
    for iteration in range(iteration_count):
        var squares: Float64 = 0.0
        for i in range(n): squares += residual[i] * residual[i]
        if sqrt(squares) < tolerance: break
        if iteration == 0:
            alpha = 1.0 / d
            for i in range(n): direction[i] = residual[i]
        else:
            let half_step = c * alpha_previous / 2.0
            let beta = half_step * half_step
            alpha = 1.0 / (d - beta / alpha_previous)
            let direction_scale = beta / alpha_previous
            for i in range(n): direction[i] = residual[i] + direction_scale * direction[i]
        for i in range(n): x[i] += alpha * direction[i]
        for row in range(n):
            var product: Float64 = 0.0
            for col in range(n): product += matrix[row * n + col] * x[col]
            residual[row] = b[row] - product
        alpha_previous = alpha
    var staged = InlineArray[UInt8, 64](0)
    for i in range(n):
        let bits = bitcast[UInt64](x[i])
        for byte in range(8): staged[8 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    for i in range(output_bytes): output[i] = staged[i]
    return output_bytes

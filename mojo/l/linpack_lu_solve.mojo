from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("linpack_lu_solve")
fn linpack_lu_solve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 22:
        return -1e300
    let dimension = input[0]
    if dimension < 2 or dimension > 4:
        return -1e300
    let n = Int(dimension)
    if length != c_size_t(1 + n * n + n):
        return -1e300
    var matrix = InlineArray[Float64, 16](fill=0.0)
    var rhs = InlineArray[Float64, 4](fill=0.0)
    var pivots = InlineArray[Int, 4](fill=0)
    for i in range(n * n):
        let value = input[1 + i]
        if value < -8 or value > 8:
            return -1e300
        matrix[i] = Float64(value)
    for i in range(n):
        let value = input[1 + n * n + i]
        if value < -32 or value > 32:
            return -1e300
        rhs[i] = Float64(value)

    for k in range(n - 1):
        var pivot = k
        var maximum = abs(matrix[n * k + k])
        for row in range(k + 1, n):
            let magnitude = abs(matrix[n * k + row])
            if magnitude > maximum:
                maximum = magnitude
                pivot = row
        if maximum == 0.0:
            return -1e300
        pivots[k] = pivot
        if pivot != k:
            let saved = matrix[n * k + pivot]
            matrix[n * k + pivot] = matrix[n * k + k]
            matrix[n * k + k] = saved
        let scale = -1.0 / matrix[n * k + k]
        for row in range(k + 1, n):
            matrix[n * k + row] *= scale
        for column in range(k + 1, n):
            let factor = matrix[n * column + pivot]
            if pivot != k:
                matrix[n * column + pivot] = matrix[n * column + k]
                matrix[n * column + k] = factor
            if factor != 0.0:
                for row in range(k + 1, n):
                    matrix[n * column + row] += factor * matrix[n * k + row]
    if matrix[n * (n - 1) + n - 1] == 0.0:
        return -1e300

    for k in range(n - 1):
        let pivot = pivots[k]
        let factor = rhs[pivot]
        if pivot != k:
            rhs[pivot] = rhs[k]
            rhs[k] = factor
        if factor != 0.0:
            for row in range(k + 1, n):
                rhs[row] += factor * matrix[n * k + row]
    for step in range(n):
        let k = n - 1 - step
        rhs[k] /= matrix[n * k + k]
        let factor = -rhs[k]
        if factor != 0.0:
            for row in range(k):
                rhs[row] += factor * matrix[n * k + row]
    var result: Float64 = 0.0
    for i in range(n):
        result += Float64(i + 1) * rhs[i]
    return result if isfinite(result) else -1e300

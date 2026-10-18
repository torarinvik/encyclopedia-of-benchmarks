package qr_eigen_values

import "core:c"
import "core:math"

@(export)
qr_eigen_values :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length != 5 || input[0] != 2 do return -1
    matrix: [4]f64
    for i in 0..<4 {
        value := input[i+1]
        if !math.is_finite(value) || value < -9 || value > 9 || math.trunc(value) != value do return -1
        matrix[i] = value
    }
    if matrix[1] != matrix[2] || matrix[1] == 0 || matrix[0] == matrix[3] do return -1
    last_eigenvalue: f64 = 0
    iterations := 0
    for math.abs(matrix[2]) > 1e-10 {
        if iterations >= 256 do return -1
        last_eigenvalue = matrix[3]
        shifted := matrix
        shifted[0] -= last_eigenvalue
        shifted[3] -= last_eigenvalue
        q, r: [4]f64
        for column in 0..<2 {
            original, residual: [2]f64
            for row in 0..<2 {
                original[row] = shifted[row*2+column]
                residual[row] = original[row]
            }
            for previous in 0..<column {
                basis: [2]f64
                for row in 0..<2 { basis[row] = q[row*2+previous] }
                denominator: f64 = 0
                for row in 0..<2 { denominator += basis[row]*basis[row] }
                if denominator == 0 || !math.is_finite(denominator) do return -1
                dot: f64 = 0
                for row in 0..<2 { dot += original[row]*basis[row] }
                scalar := dot/denominator
                for row in 0..<2 { residual[row] -= scalar*basis[row] }
            }
            norm_squared: f64 = 0
            for row in 0..<2 { norm_squared += residual[row]*residual[row] }
            norm := math.sqrt_f64(norm_squared)
            if norm == 0 || !math.is_finite(norm) do return -1
            for row in 0..<2 { q[row*2+column] = residual[row]/norm }
            for target in column..<2 {
                dot: f64 = 0
                for row in 0..<2 { dot += q[row*2+column]*shifted[row*2+target] }
                r[column*2+target] = dot
            }
        }
        updated: [4]f64
        for row in 0..<2 {
            for column in 0..<2 {
                for inner in 0..<2 { updated[row*2+column] += r[row*2+inner]*q[inner*2+column] }
            }
        }
        updated[0] += last_eigenvalue
        updated[3] += last_eigenvalue
        for i in 0..<4 {
            if !math.is_finite(updated[i]) do return -1
            matrix[i] = updated[i]
        }
        iterations += 1
    }
    result0, result1 := matrix[0], last_eigenvalue
    if !math.is_finite(result0) || !math.is_finite(result1) do return -1
    staged := [2]f64{result0, result1}
    if output == nil || capacity < 2 do return -2
    output[0], output[1] = staged[0], staged[1]
    return 2
}

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("wire_sizing")
fn wire_sizing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 17: return -1
    if input[0] < 1 or input[0] > 6: return -1
    let n = Int(input[0])
    if Int(length) != 5 + 2 * n: return -1
    for i in range(1, 5):
        if input[i] < 1 or input[i] > 1000: return -1
    for i in range(n):
        if input[5 + i] < 1 or input[5 + i] > 32 or input[5 + n + i] < 1 or input[5 + n + i] > 1000: return -1
        if i > 0 and (input[5 + i] >= input[4 + i] or input[5 + n + i] >= input[4 + n + i]): return -1
    let wire_length = Float64(input[1])
    let rd = Float64(input[2])
    let cl = Float64(input[3])
    let r0 = Float64(input[4])
    var phi = InlineArray[Float64, 36](fill=0.0)
    var rho = InlineArray[Float64, 6](fill=0.0)
    for i in range(n):
        rho[i] = rd * Float64(input[5 + n + i]) + cl * r0 / Float64(input[5 + i])
        for j in range(n):
            phi[6 * i + j] = r0 * Float64(input[5 + n + max(i, j)]) / Float64(input[5 + min(i, j)])
    var best: Float64 = 0.0
    var best_lengths = InlineArray[Float64, 6](fill=0.0)
    var found = False
    for mask in range(1, 1 << n):
        var ids = InlineArray[Int, 6](fill=0)
        var k = 0
        for i in range(n):
            if (mask & (1 << i)) != 0:
                ids[k] = i
                k += 1
        var matrix = InlineArray[Float64, 56](fill=0.0)
        for row in range(k):
            for col in range(k): matrix[8 * row + col] = phi[6 * ids[row] + ids[col]]
            matrix[8 * row + k] = 1.0
            matrix[8 * row + k + 1] = -rho[ids[row]]
        for col in range(k): matrix[8 * k + col] = 1.0
        matrix[8 * k + k + 1] = wire_length
        var ok = True
        for col in range(k + 1):
            var pivot = col
            for row in range(col + 1, k + 1):
                if abs(matrix[8 * row + col]) > abs(matrix[8 * pivot + col]): pivot = row
            if abs(matrix[8 * pivot + col]) < 1.0e-12:
                ok = False
                break
            if pivot != col:
                for j in range(k + 2):
                    let temp = matrix[8 * pivot + j]
                    matrix[8 * pivot + j] = matrix[8 * col + j]
                    matrix[8 * col + j] = temp
            let divisor = matrix[8 * col + col]
            for j in range(col, k + 2): matrix[8 * col + j] /= divisor
            for row in range(k + 1):
                if row == col: continue
                let factor = matrix[8 * row + col]
                for j in range(col, k + 2): matrix[8 * row + j] -= factor * matrix[8 * col + j]
        if not ok: continue
        var x = InlineArray[Float64, 6](fill=0.0)
        for i in range(k): x[ids[i]] = matrix[8 * i + k + 1]
        let lambda = matrix[8 * k + k + 1]
        var total: Float64 = 0.0
        for i in range(n):
            if x[i] < -1.0e-8: ok = False
            total += x[i]
            var gradient = rho[i] + lambda
            for j in range(n): gradient += phi[6 * i + j] * x[j]
            if (mask & (1 << i)) == 0 and gradient < -1.0e-7: ok = False
        if abs(total - wire_length) > 1.0e-7: ok = False
        if not ok: continue
        var objective = rd * cl
        for i in range(n):
            objective += rho[i] * x[i]
            for j in range(n): objective += 0.5 * x[i] * phi[6 * i + j] * x[j]
        if not found or objective < best - 1.0e-7:
            found = True
            best = objective
            best_lengths = x
    if not found: return -1
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(n + 1):
        var value = Int64(best * 1000000.0 + 0.5)
        if word > 0: value = Int64(max(best_lengths[word - 1], 0.0) * 1000000.0 + 0.5)
        var bits = bitcast[UInt64](value)
        for b in range(8):
            output[8 * word + b] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)

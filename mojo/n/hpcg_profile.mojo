from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_COARSE = 16
comptime MAX_STEPS = 12
comptime MAX_MICRO: Int64 = 1_000_000_000
comptime SCALE = 1_000_000.0

fn hpcg_matvec(values: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, nnz: Int,
               vector: InlineArray[Float64, 32]) -> InlineArray[Float64, 32]:
    var product = InlineArray[Float64, 32]()
    let col = 4 + n
    let val = col + nnz
    for row in range(n):
        var total: Float64 = 0.0
        for edge in range(Int(values[3 + row]), Int(values[4 + row])):
            total += Float64(values[val + edge]) / SCALE * vector[Int(values[col + edge])]
        product[row] = total
    return product

fn hpcg_coarse_solve(values: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, nnz: Int,
                     rhs: InlineArray[Float64, 16]) -> InlineArray[Float64, 16]:
    let cn = (n + 1) // 2
    let col = 4 + n
    let val = col + nnz
    var matrix = InlineArray[Float64, 256]()
    var lower = InlineArray[Float64, 256]()
    for row in range(n):
        for edge in range(Int(values[3 + row]), Int(values[4 + row])):
            let index = (row // 2) * MAX_COARSE + Int(values[col + edge]) // 2
            matrix[index] += Float64(values[val + edge]) / SCALE
    for i in range(cn):
        for j in range(i + 1):
            var value = matrix[i * MAX_COARSE + j]
            for k in range(j):
                value -= lower[i * MAX_COARSE + k] * lower[j * MAX_COARSE + k]
            if i == j:
                lower[i * MAX_COARSE + j] = sqrt(value)
            else:
                lower[i * MAX_COARSE + j] = value / lower[j * MAX_COARSE + j]
    var intermediate = InlineArray[Float64, 16]()
    for i in range(cn):
        var value = rhs[i]
        for j in range(i):
            value -= lower[i * MAX_COARSE + j] * intermediate[j]
        intermediate[i] = value / lower[i * MAX_COARSE + i]
    var result = InlineArray[Float64, 16]()
    for ii in range(cn):
        let i = cn - 1 - ii
        var value = intermediate[i]
        for j in range(i + 1, cn):
            value -= lower[j * MAX_COARSE + i] * result[j]
        result[i] = value / lower[i * MAX_COARSE + i]
    return result

fn hpcg_precondition(values: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, nnz: Int,
                     residual: InlineArray[Float64, 32]) -> InlineArray[Float64, 32]:
    let col = 4 + n
    let val = col + nnz
    var pre = InlineArray[Float64, 32]()
    for row in range(n):
        var value = residual[row]
        var diagonal: Float64 = 0.0
        for edge in range(Int(values[3 + row]), Int(values[4 + row])):
            let c = Int(values[col + edge])
            if c == row:
                diagonal = Float64(values[val + edge]) / SCALE
            elif c < row:
                value -= Float64(values[val + edge]) / SCALE * pre[c]
        pre[row] = value / diagonal

    let pre_product = hpcg_matvec(values, n, nnz, pre)
    var coarse_rhs = InlineArray[Float64, 16]()
    for row in range(n):
        coarse_rhs[row // 2] += residual[row] - pre_product[row]
    let coarse = hpcg_coarse_solve(values, n, nnz, coarse_rhs)
    var middle = InlineArray[Float64, 32]()
    for row in range(n):
        middle[row] = pre[row] + coarse[row // 2]

    let middle_product = hpcg_matvec(values, n, nnz, middle)
    var post = InlineArray[Float64, 32]()
    for reverse in range(n):
        let row = n - 1 - reverse
        var value = residual[row] - middle_product[row]
        var diagonal: Float64 = 0.0
        for edge in range(Int(values[3 + row]), Int(values[4 + row])):
            let c = Int(values[col + edge])
            if c == row:
                diagonal = Float64(values[val + edge]) / SCALE
            elif c > row:
                value -= Float64(values[val + edge]) / SCALE * post[c]
        post[row] = value / diagonal
    var result = InlineArray[Float64, 32]()
    for row in range(n):
        result[row] = middle[row] + post[row]
    return result

fn hpcg_validate(values: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Bool:
    if length < 8 or length > 452:
        return False
    if values[0] < 1 or values[0] > Int64(MAX_N) or values[1] < 1 or
       values[1] > Int64(MAX_STEPS) or values[1] > values[0] or
       values[2] < values[0] or values[2] > 6 * values[0]:
        return False
    let n = Int(values[0])
    let steps = Int(values[1])
    let nnz = Int(values[2])
    if steps > min(MAX_STEPS, n) or length != 4 + 2 * n + 2 * nnz:
        return False
    let col = 4 + n
    let val = col + nnz
    let rhs = val + nnz
    if values[3] != 0 or values[3 + n] != Int64(nnz):
        return False
    for row in range(n):
        let begin = Int(values[3 + row])
        let end = Int(values[4 + row])
        if begin < 0 or begin >= end or end > nnz or end - begin > 6:
            return False
        var diagonal: Int64 = 0
        var off_sum: Int64 = 0
        var previous = -1
        for edge in range(begin, end):
            let c = values[col + edge]
            let a = values[val + edge]
            if c < 0 or c >= Int64(n) or c <= previous or a == 0 or
               a < -MAX_MICRO or a > MAX_MICRO:
                return False
            previous = Int(c)
            if Int(c) == row:
                diagonal = a
            else:
                off_sum += if a < 0 then -a else a
        if diagonal <= 0 or diagonal <= off_sum or values[rhs + row] < -MAX_MICRO or
           values[rhs + row] > MAX_MICRO:
            return False
    for row in range(n):
        for edge in range(Int(values[3 + row]), Int(values[4 + row])):
            let c = Int(values[col + edge])
            var found = False
            for reverse in range(Int(values[3 + c]), Int(values[4 + c])):
                if values[col + reverse] == Int64(row) and values[val + reverse] == values[val + edge]:
                    found = True
                    break
            if not found:
                return False
    return True

@export("hpcg_profile")
fn hpcg_profile(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or not hpcg_validate(values, Int(length)):
        return -1
    let n = Int(values[0])
    let steps = Int(values[1])
    let nnz = Int(values[2])
    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    let rhs = 4 + n + 2 * nnz
    var b = InlineArray[Float64, 32]()
    var x = InlineArray[Float64, 32]()
    var residual = InlineArray[Float64, 32]()
    var z = InlineArray[Float64, 32]()
    var direction = InlineArray[Float64, 32]()
    var product = InlineArray[Float64, 32]()
    var ax = InlineArray[Float64, 32]()
    var b_squared: Float64 = 0.0
    for i in range(n):
        b[i] = Float64(values[rhs + i]) / SCALE
        residual[i] = b[i]
        b_squared += b[i] * b[i]
    if b_squared > 0.0:
        z = hpcg_precondition(values, n, nnz, residual)
        direction = z
        var rho: Float64 = 0.0
        for i in range(n):
            rho += residual[i] * z[i]
        if not (rho > 0.0) or not isfinite(rho):
            return -1
        for _ in range(steps):
            product = hpcg_matvec(values, n, nnz, direction)
            var curvature: Float64 = 0.0
            for i in range(n):
                curvature += direction[i] * product[i]
            if not (curvature > 0.0) or not isfinite(curvature):
                return -1
            let alpha = rho / curvature
            for i in range(n):
                x[i] += alpha * direction[i]
                residual[i] -= alpha * product[i]
            var r_squared: Float64 = 0.0
            for i in range(n):
                r_squared += residual[i] * residual[i]
            if r_squared <= b_squared * 1.0e-28:
                break
            let next_z = hpcg_precondition(values, n, nnz, residual)
            var next_rho: Float64 = 0.0
            for i in range(n):
                next_rho += residual[i] * next_z[i]
            if not (next_rho > 0.0) or not isfinite(next_rho):
                return -1
            let beta = next_rho / rho
            for i in range(n):
                z[i] = next_z[i]
                direction[i] = z[i] + beta * direction[i]
            rho = next_rho
    ax = hpcg_matvec(values, n, nnz, x)
    var residual_squared: Float64 = 0.0
    for i in range(n):
        let difference = b[i] - ax[i]
        residual_squared += difference * difference
        let bits = bitcast[UInt64](x[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    let norm = sqrt(residual_squared)
    let bits = bitcast[UInt64](norm)
    for byte in range(8):
        output[n * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(output_bytes)

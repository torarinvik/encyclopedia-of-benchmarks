from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_OUTER = 8
comptime MAX_STEPS = 25
comptime MAX_MICRO: Int64 = 1_000_000_000
comptime SCALE = 1_000_000.0

fn npb_validate(values: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Bool:
    if length < 8 or length > MAX_N + 6 + 2 * (MAX_N * 6):
        return False
    if values[0] < 1 or values[0] > Int64(MAX_N) or values[1] < 1 or values[1] > Int64(MAX_OUTER) or
        values[2] < 1 or values[2] > Int64(MAX_STEPS) or values[2] > values[0] or
        values[3] < -MAX_MICRO or values[3] > MAX_MICRO or values[4] < values[0] or
        values[4] > 6 * values[0]:
        return False
    let n = Int(values[0])
    let nnz = Int(values[4])
    if length != n + 6 + 2 * nnz:
        return False
    let rp = 5
    let cols = rp + n + 1
    let entries = cols + nnz
    if values[rp] != 0 or values[rp + n] != Int64(nnz):
        return False
    for row in range(n):
        let begin = Int(values[rp + row])
        let end = Int(values[rp + row + 1])
        if begin < 0 or begin >= end or end > nnz:
            return False
        var diagonal: Int64 = 0
        var off_sum: Int64 = 0
        var previous = -1
        for edge in range(begin, end):
            let column = values[cols + edge]
            let entry = values[entries + edge]
            if column < 0 or column >= Int64(n) or column <= previous or entry == 0 or
                entry < -MAX_MICRO or entry > MAX_MICRO:
                return False
            previous = Int(column)
            if Int(column) == row:
                diagonal = entry
            else:
                off_sum += if entry < 0 then -entry else entry
        if diagonal <= 0 or diagonal <= off_sum:
            return False
    for row in range(n):
        for edge in range(Int(values[rp + row]), Int(values[rp + row + 1])):
            let column = Int(values[cols + edge])
            var found = False
            for reverse in range(Int(values[rp + column]), Int(values[rp + column + 1])):
                if values[cols + reverse] == Int64(row) and values[entries + reverse] == values[entries + edge]:
                    found = True
                    break
            if not found:
                return False
    return True

@export("npb_cg_sparse_inverse_power")
fn npb_cg_sparse_inverse_power(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or not npb_validate(values, Int(length)):
        return -1
    let n = Int(values[0])
    let outer_count = Int(values[1])
    let steps = Int(values[2])
    let nnz = Int(values[4])
    let output_bytes = outer_count * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    let rp = 5
    let cols = rp + n + 1
    let entries = cols + nnz
    var x = InlineArray[Float64, 32]()
    var z = InlineArray[Float64, 32]()
    var residual = InlineArray[Float64, 32]()
    var direction = InlineArray[Float64, 32]()
    var product = InlineArray[Float64, 32]()
    var az = InlineArray[Float64, 32]()
    for i in range(n):
        x[i] = 1.0
    for outer in range(outer_count):
        var rhs2: Float64 = 0.0
        for i in range(n):
            z[i] = 0.0
            residual[i] = x[i]
            direction[i] = x[i]
            rhs2 += residual[i] * residual[i]
        var rr = rhs2
        for _ in range(steps):
            if rr <= 0.0:
                break
            for row in range(n):
                var total: Float64 = 0.0
                for edge in range(Int(values[rp + row]), Int(values[rp + row + 1])):
                    total += Float64(values[entries + edge]) / SCALE * direction[Int(values[cols + edge])]
                product[row] = total
            var denominator: Float64 = 0.0
            for i in range(n):
                denominator += direction[i] * product[i]
            if not (denominator > 0.0) or not isfinite(denominator):
                return -1
            let alpha = rr / denominator
            for i in range(n):
                z[i] += alpha * direction[i]
                residual[i] -= alpha * product[i]
            var next: Float64 = 0.0
            for i in range(n):
                next += residual[i] * residual[i]
            if next <= rhs2 * 1.0e-28:
                rr = next
                break
            let beta = next / rr
            for i in range(n):
                direction[i] = residual[i] + beta * direction[i]
            rr = next
        for row in range(n):
            var total: Float64 = 0.0
            for edge in range(Int(values[rp + row]), Int(values[rp + row + 1])):
                total += Float64(values[entries + edge]) / SCALE * z[Int(values[cols + edge])]
            az[row] = total
        var explicit2: Float64 = 0.0
        var dot: Float64 = 0.0
        var z2: Float64 = 0.0
        for i in range(n):
            let difference = x[i] - az[i]
            explicit2 += difference * difference
            dot += x[i] * z[i]
            z2 += z[i] * z[i]
        if not (dot > 0.0) or not (z2 > 0.0) or not isfinite(dot) or not isfinite(z2):
            return -1
        let estimate = Float64(values[3]) / SCALE + 1.0 / dot
        let residual_norm = sqrt(explicit2)
        if not isfinite(estimate) or not isfinite(residual_norm):
            return -1
        let estimate_bits = bitcast[UInt64](estimate)
        let residual_bits = bitcast[UInt64](residual_norm)
        for byte in range(8):
            output[outer * 16 + byte] = UInt8((estimate_bits >> UInt(8 * byte)) & 255)
            output[outer * 16 + 8 + byte] = UInt8((residual_bits >> UInt(8 * byte)) & 255)
        let z_norm = sqrt(z2)
        for i in range(n):
            x[i] = z[i] / z_norm
    return Int64(output_bytes)

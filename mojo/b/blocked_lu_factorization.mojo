from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime BLU_MAX_N = 8
comptime BLU_MAX_INPUT = 66
comptime BLU_MAX_OUTPUT = 128

@export("blocked_lu_factorization")
fn blocked_lu_factorization(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 1 or input_length > BLU_MAX_INPUT:
        return -1
    let raw_n = input[0]
    if not isfinite(raw_n) or raw_n < 2 or raw_n > BLU_MAX_N or Float64(Int(raw_n)) != raw_n:
        return -1
    let n = Int(raw_n)
    if (n % 2) != 0 or input_length != c_size_t(1 + n * n): return -1

    var schur = InlineArray[Float64, 64](fill=0.0)
    for row in range(n):
        var off_sum: Int64 = 0
        for col in range(n):
            let x = input[1 + row * n + col]
            if not isfinite(x): return -1
            if row == col:
                if x < 1 or x > 16: return -1
            else:
                if x < -2 or x > 2: return -1
            if Float64(Int(x)) != x: return -1
            let value = Int64(Int(x))
            if row == col:
                if value < 1 or value > 16: return -1
            else:
                if value < -2 or value > 2: return -1
                if value < 0: off_sum -= value
                else: off_sum += value
            schur[row * n + col] = Float64(value)
        if Int64(schur[row * n + row]) <= off_sum: return -1

    var lower = InlineArray[Float64, 64](fill=0.0)
    var upper = InlineArray[Float64, 64](fill=0.0)
    for k in range(0, n, 2):
        let u00 = schur[k * n + k]
        let u01 = schur[k * n + k + 1]
        if not isfinite(u00) or u00 == 0: return -1
        let l10 = schur[(k + 1) * n + k] / u00
        let u11 = schur[(k + 1) * n + k + 1] - l10 * u01
        if not isfinite(l10) or not isfinite(u11) or u11 == 0: return -1
        lower[k * n + k] = 1
        lower[(k + 1) * n + k] = l10
        lower[(k + 1) * n + k + 1] = 1
        upper[k * n + k] = u00
        upper[k * n + k + 1] = u01
        upper[(k + 1) * n + k + 1] = u11
        for j in range(k + 2, n, 2):
            for col in range(j, j + 2):
                let s0 = schur[k * n + col]
                let s1 = schur[(k + 1) * n + col]
                upper[k * n + col] = s0
                upper[(k + 1) * n + col] = s1 - l10 * s0
        for i in range(k + 2, n, 2):
            for row in range(i, i + 2):
                let s0 = schur[row * n + k]
                let s1 = schur[row * n + k + 1]
                let l0 = s0 / u00
                let l1 = (s1 - l0 * u01) / u11
                lower[row * n + k] = l0
                lower[row * n + k + 1] = l1
        for i in range(k + 2, n, 2):
            for j in range(k + 2, n, 2):
                for row in range(i, i + 2):
                    for col in range(j, j + 2):
                        let update = lower[row * n + k] * upper[k * n + col] + lower[row * n + k + 1] * upper[(k + 1) * n + col]
                        schur[row * n + col] = schur[row * n + col] - update

    var staged = InlineArray[Float64, 128](fill=0.0)
    let m = n * n
    for row in range(n):
        lower[row * n + row] = 1
        for col in range(row, n): upper[row * n + col] = schur[row * n + col]
    for i in range(m):
        if not isfinite(lower[i]) or not isfinite(upper[i]): return -1
        staged[i] = lower[i]
        staged[m + i] = upper[i]
    let output_length = 2 * m
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(output_length): return -2
    for i in range(output_length): output[i] = staged[i]
    return Int64(output_length)

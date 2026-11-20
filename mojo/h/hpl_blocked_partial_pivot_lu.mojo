from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime HPL_MAX_N = 8
comptime HPL_MAX_INPUT = 66
comptime HPL_MAX_OUTPUT = 72

@export("hpl_blocked_partial_pivot_lu")
fn hpl_blocked_partial_pivot_lu(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 1 or input_length > HPL_MAX_INPUT:
        return -1
    let raw_n = input[0]
    if not isfinite(raw_n) or raw_n < 2 or raw_n > HPL_MAX_N or Float64(Int(raw_n)) != raw_n:
        return -1
    let n = Int(raw_n)
    if input_length != c_size_t(1 + n * n): return -1

    var a = InlineArray[Float64, 64](fill=0.0)
    for i in range(n * n):
        let x = input[i + 1]
        if not isfinite(x) or x < -16 or x > 16 or Float64(Int(x)) != x: return -1
        a[i] = x
    var pivots = InlineArray[Int64, 8](fill=0)
    var panel = 0
    while panel < n:
        let panel_end = min(panel + 2, n)
        for col in range(panel, panel_end):
            var pivot_row = col
            var pivot_magnitude = a[col * n + col]
            if pivot_magnitude < 0: pivot_magnitude = -pivot_magnitude
            for row in range(col + 1, n):
                var magnitude = a[row * n + col]
                if magnitude < 0: magnitude = -magnitude
                if magnitude > pivot_magnitude:
                    pivot_magnitude = magnitude
                    pivot_row = row
            if not isfinite(pivot_magnitude) or pivot_magnitude == 0: return -1
            pivots[col] = Int64(pivot_row)
            if pivot_row != col:
                for j in range(n):
                    let temporary = a[col * n + j]
                    a[col * n + j] = a[pivot_row * n + j]
                    a[pivot_row * n + j] = temporary
            let diagonal = a[col * n + col]
            if not isfinite(diagonal) or diagonal == 0: return -1
            for row in range(col + 1, n):
                a[row * n + col] = a[row * n + col] / diagonal
                if not isfinite(a[row * n + col]): return -1
                let multiplier = a[row * n + col]
                for j in range(col + 1, panel_end):
                    a[row * n + j] = a[row * n + j] - multiplier * a[col * n + j]
                    if not isfinite(a[row * n + j]): return -1
        for row in range(panel, panel_end):
            for col in range(panel_end, n):
                var value = a[row * n + col]
                for inner in range(panel, row):
                    value = value - a[row * n + inner] * a[inner * n + col]
                if not isfinite(value): return -1
                a[row * n + col] = value
        for row in range(panel_end, n):
            for col in range(panel_end, n):
                var update: Float64 = 0.0
                for inner in range(panel, panel_end):
                    update = update + a[row * n + inner] * a[inner * n + col]
                a[row * n + col] = a[row * n + col] - update
                if not isfinite(a[row * n + col]): return -1
        panel = panel_end

    var staged = InlineArray[Float64, 72](fill=0.0)
    for i in range(n): staged[i] = Float64(pivots[i])
    for i in range(n * n):
        if not isfinite(a[i]): return -1
        staged[n + i] = a[i]
    let output_length = n + n * n
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(output_length):
        return -2
    for i in range(output_length): output[i] = staged[i]
    return Int64(output_length)

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 16

@export("npb_sp_pentadiagonal_line_solve")
fn npb_sp_pentadiagonal_line_solve(input: UnsafePointer[Float64, ImmutAnyOrigin],
        input_length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 31 or input_length > 97:
        return -1
    let n_value = input[0]
    if n_value != n_value or n_value < 5.0 or n_value > 16.0 or n_value != Float64(Int(n_value)):
        return -1
    let n = Int(n_value)
    if input_length != c_size_t(1 + 6*n): return -1
    if input[1] != 0.0 or input[2] != 0.0 or input[1+n] != 0.0 or
        input[4*n] != 0.0 or input[5*n-1] != 0.0 or input[5*n] != 0.0:
        return -1
    var lower2 = InlineArray[Float64, MAX_N]()
    var lower1 = InlineArray[Float64, MAX_N]()
    var diagonal = InlineArray[Float64, MAX_N]()
    var upper1 = InlineArray[Float64, MAX_N]()
    var upper2 = InlineArray[Float64, MAX_N]()
    var rhs = InlineArray[Float64, MAX_N]()
    for row in range(n):
        lower2[row] = input[1+row]
        lower1[row] = input[1+n+row]
        diagonal[row] = input[1+2*n+row]
        upper1[row] = input[1+3*n+row]
        upper2[row] = input[1+4*n+row]
        rhs[row] = input[1+5*n+row]
        let bands = (lower2[row], lower1[row], upper1[row], upper2[row])
        var radius: Float64 = 0.0
        for band in bands:
            if band != band or abs(band) > 2.0: return -1
            radius += abs(band)
        if diagonal[row] != diagonal[row] or diagonal[row] < 5.0 or diagonal[row] > 16.0 or
            rhs[row] != rhs[row] or rhs[row] < -64.0 or rhs[row] > 64.0 or diagonal[row]-radius < 0.25:
            return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(n): return -2
    var lo1 = InlineArray[Float64, MAX_N]()
    var diag = InlineArray[Float64, MAX_N]()
    var up1 = InlineArray[Float64, MAX_N]()
    var up2 = InlineArray[Float64, MAX_N]()
    var work_rhs = InlineArray[Float64, MAX_N]()
    var solution = InlineArray[Float64, MAX_N]()
    for row in range(n):
        lo1[row] = lower1[row]; diag[row] = diagonal[row]
        up1[row] = upper1[row]; up2[row] = upper2[row]; work_rhs[row] = rhs[row]
    for pivot_row in range(n):
        let pivot = diag[pivot_row]
        if pivot_row + 1 < n:
            let row = pivot_row + 1
            let factor = lo1[row] / pivot
            diag[row] -= factor * up1[pivot_row]
            up1[row] -= factor * up2[pivot_row]
            work_rhs[row] -= factor * work_rhs[pivot_row]
        if pivot_row + 2 < n:
            let row = pivot_row + 2
            let factor = lower2[row] / pivot
            lo1[row] -= factor * up1[pivot_row]
            diag[row] -= factor * up2[pivot_row]
            work_rhs[row] -= factor * work_rhs[pivot_row]
    for back in range(n-1, -1, -1):
        var value = work_rhs[back]
        if back + 1 < n: value -= up1[back] * solution[back+1]
        if back + 2 < n: value -= up2[back] * solution[back+2]
        solution[back] = value / diag[back]
    for row in range(n): output[row] = solution[row]
    return Int64(n)

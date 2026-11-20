from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias INVALID_RESULT = -1

@export("minimum_area_rectangle_arbitrary_orientation")
fn minimum_area_rectangle_arbitrary_orientation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34:
        return INVALID_RESULT
    let n_value = input[0]
    if n_value < 4 or n_value > MAX_N: return INVALID_RESULT
    let n = Int(n_value)
    if length != 1 + 2 * n: return INVALID_RESULT

    var xs = InlineArray[Int64, 16](fill=0)
    var ys = InlineArray[Int64, 16](fill=0)
    for i in range(n):
        xs[i] = input[1 + 2 * i]
        ys[i] = input[2 + 2 * i]
        if xs[i] < -32 or xs[i] > 32 or ys[i] < -32 or ys[i] > 32:
            return INVALID_RESULT
        for j in range(i):
            if xs[i] == xs[j] and ys[i] == ys[j]: return INVALID_RESULT

    var best: Int64 = -1
    for i in range(n):
        for j in range(i + 1, n):
            let dx1 = xs[i] - xs[j]
            let dy1 = ys[i] - ys[j]
            let mid_x = xs[i] + xs[j]
            let mid_y = ys[i] + ys[j]
            let len1 = dx1 * dx1 + dy1 * dy1
            for k in range(n):
                for l in range(k + 1, n):
                    if k < i or (k == i and l <= j): continue
                    if k == i or k == j or l == i or l == j: continue
                    if mid_x != xs[k] + xs[l] or mid_y != ys[k] + ys[l]: continue
                    let dx2 = xs[k] - xs[l]
                    let dy2 = ys[k] - ys[l]
                    if len1 != dx2 * dx2 + dy2 * dy2: continue
                    let cross = dx1 * dy2 - dy1 * dx2
                    let area2 = if cross < 0: -cross else: cross
                    if best < 0 or area2 < best: best = area2
    if best < 0: 0 else: best

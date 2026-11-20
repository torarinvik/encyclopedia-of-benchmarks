from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 24

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    return isfinite(value) and value >= Float64(low) and value <= Float64(high) and Float64(Int(value)) == value

fn de_boor(p: Int, n: Int, u: Float64,
           input: UnsafePointer[Float64, ImmutAnyOrigin]) -> Float64:
    let knot_count = n+p+1
    var span = p
    if u == input[3+n]: span = n-1
    else:
        while span < n-1 and u >= input[3+span+1]: span += 1
    var local = InlineArray[Float64, 4](fill=0.0)
    for j in range(0,p+1): local[j] = input[3+knot_count+span-p+j]
    for level in range(1,p+1):
        for slot in range(p,level-1,-1):
            let left = span-p+slot
            let right = span+slot-level+1
            let denominator = input[3+right]-input[3+left]
            let alpha = 0.0 if denominator == 0.0 else (u-input[3+left])/denominator
            local[slot] = (1.0-alpha)*local[slot-1]+alpha*local[slot]
    return local[p]

@export("de_boor_bspline_curve_evaluation")
fn de_boor_bspline_curve_evaluation(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or input_length > MAX_INPUT_LENGTH: return -1
    if not exact_integer(input[0],1,3) or not isfinite(input[2]): return -1
    let p = Int(input[0])
    if not exact_integer(input[1],p+1,8): return -1
    let n = Int(input[1])
    let knot_count = n+p+1
    if input_length != 3+knot_count+n: return -1
    var run = 1
    for i in range(0,knot_count):
        if not isfinite(input[3+i]) or input[3+i] < -1000.0 or input[3+i] > 1000.0: return -1
        if i > 0:
            if input[3+i] < input[2+i]: return -1
            run = run+1 if input[3+i] == input[2+i] else 1
            if run > p+1: return -1
    for i in range(0,n):
        if not isfinite(input[3+knot_count+i]) or input[3+knot_count+i] < -1000.0 or input[3+knot_count+i] > 1000.0: return -1
    if not (input[3+p] < input[3+n] and input[2] >= input[3+p] and input[2] <= input[3+n]): return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let result = de_boor(p,n,input[2],input)
    if not isfinite(result): return -1
    output[0] = result
    return 1

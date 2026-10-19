from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cosine_similarity")
fn cosine_similarity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 132: return -1.0e300
    let left_n = input[0]
    let right_n = input[1]
    if left_n < 0 or left_n > 64 or right_n < 0 or right_n > 64 or length != 2 + left_n + right_n: return -1.0e300
    var left = InlineArray[Int64, 95](0)
    var right = InlineArray[Int64, 95](0)
    for i in range(left_n):
        var ch = input[2 + i]
        if ch < 32 or ch > 126: return -1.0e300
        if ch >= 65 and ch <= 90: ch += 32
        left[ch - 32] += 1
    for i in range(right_n):
        var ch = input[2 + left_n + i]
        if ch < 32 or ch > 126: return -1.0e300
        if ch >= 65 and ch <= 90: ch += 32
        right[ch - 32] += 1
    var dot: Float64 = 0.0
    var left_sq: Float64 = 0.0
    var right_sq: Float64 = 0.0
    for i in range(95):
        let a = Float64(left[i])
        let b = Float64(right[i])
        dot += a * b
        left_sq += a * a
        right_sq += b * b
    if left_sq <= 0.0 or right_sq <= 0.0: return 0.0
    return dot / (sqrt(left_sq) * sqrt(right_sq))

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mpca_store_i64(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], position: Int):
    var bits: UInt64 = value.bitcast[UInt64]()
    for byte in range(8):
        output[position + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("min_plus_convolution_convex_arbitrary")
fn min_plus_convolution_convex_arbitrary(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 67: return -1
    let n_arg = input[0]
    let m_arg = input[1]
    if n_arg < 1 or n_arg > 32 or m_arg < 1 or m_arg > 32: return -1
    let n = Int(n_arg)
    let m = Int(m_arg)
    if length != c_size_t(2 + n + m): return -1
    var a = InlineArray[Int64, 32](fill=0)
    var b = InlineArray[Int64, 32](fill=0)
    for i in range(n + m):
        let value = input[2 + i]
        if value < 0 or value > 1_000_000_000: return -1
        if i < n: a[i] = value
        else: b[i - n] = value
    var i = 0
    while i + 2 < n:
        if a[i + 1] - a[i] > a[i + 2] - a[i + 1]: return -1
        i += 1
    let count = n + m - 1
    let bytes = 8 * count
    if bytes > 504: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var result = InlineArray[Int64, 63](fill=0)
    var sl = InlineArray[Int, 128](fill=0)
    var sr = InlineArray[Int, 128](fill=0)
    var so_l = InlineArray[Int, 128](fill=0)
    var so_r = InlineArray[Int, 128](fill=0)
    var top = 1
    sl[0] = 0; sr[0] = count - 1; so_l[0] = 0; so_r[0] = m - 1
    while top > 0:
        top -= 1
        let left = sl[top]; let right = sr[top]
        let opt_left = so_l[top]; let opt_right = so_r[top]
        if left <= right:
            let mid = left + (right - left) / 2
            let low = max(opt_left, max(0, mid - (n - 1)))
            let high = min(opt_right, min(m - 1, mid))
            var best: Int64 = 9_223_372_036_854_775_807
            var best_j = low
            for j in range(low, high + 1):
                let candidate = a[mid - j] + b[j]
                if candidate < best: best = candidate; best_j = j
            result[mid] = best
            if mid < right:
                sl[top] = mid + 1; sr[top] = right; so_l[top] = best_j; so_r[top] = opt_right; top += 1
            if left < mid:
                sl[top] = left; sr[top] = mid - 1; so_l[top] = opt_left; so_r[top] = best_j; top += 1
    for i in range(count): mpca_store_i64(result[i], output, 8 * i)
    return Int64(bytes)

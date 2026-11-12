from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mpcc_store_i64(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], position: Int):
    var bits: UInt64 = value.bitcast[UInt64]()
    for byte in range(8):
        output[position + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("min_plus_convolution_convex_convex")
fn min_plus_convolution_convex_convex(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 259: return -1
    let n_arg = input[0]
    let m_arg = input[1]
    if n_arg < 1 or n_arg > 128 or m_arg < 1 or m_arg > 128: return -1
    let n = Int(n_arg)
    let m = Int(m_arg)
    if length != c_size_t(2 + n + m): return -1
    var a = InlineArray[Int64, 128](fill=0)
    var b = InlineArray[Int64, 128](fill=0)
    for i in range(n + m):
        let value = input[2 + i]
        if value < 0 or value > 1_000_000_000: return -1
        if i < n: a[i] = value
        else: b[i - n] = value
    var i = 0
    while i + 2 < n:
        if a[i + 1] - a[i] > a[i + 2] - a[i + 1]: return -1
        i += 1
    i = 0
    while i + 2 < m:
        if b[i + 1] - b[i] > b[i + 2] - b[i + 1]: return -1
        i += 1
    let count = n + m - 1
    let bytes = 8 * count
    if bytes > 2040: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var result = InlineArray[Int64, 255](fill=0)
    result[0] = a[0] + b[0]
    var ai = 0
    var bi = 0
    var out = 1
    while ai + 1 < n or bi + 1 < m:
        var slope: Int64 = 0
        if bi + 1 == m or (ai + 1 < n and a[ai + 1] - a[ai] <= b[bi + 1] - b[bi]):
            slope = a[ai + 1] - a[ai]
            ai += 1
        else:
            slope = b[bi + 1] - b[bi]
            bi += 1
        result[out] = result[out - 1] + slope
        out += 1
    for i in range(count): mpcc_store_i64(result[i], output, 8 * i)
    return Int64(bytes)

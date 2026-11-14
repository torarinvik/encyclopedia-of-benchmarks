# Bounded dyadic relaxed-convolution profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("relaxed_convolution")
fn relaxed_convolution(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 33: return -1
    let count = input[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 2 * count): return -1
    let n = Int(count)
    var a = InlineArray[Int64, 16](fill=0)
    var b = InlineArray[Int64, 16](fill=0)
    var c = InlineArray[Int64, 16](fill=0)
    for i in range(n):
        let av = input[1 + i]
        let bv = input[1 + n + i]
        if av < 0 or av >= 998244353 or bv < 0 or bv >= 998244353: return -1
        a[i] = av
        b[i] = bv
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(4 * n): return -2
    for index in range(n):
        c[index] = (c[index] + a[index] * b[0]) % 998244353
        if index > 0: c[index] = (c[index] + b[index] * a[0]) % 998244353
        let q = index + 1
        var d = 1
        while d <= q:
            if q % (2 * d) == d:
                let end = min(q + d, n)
                if q == d:
                    for i in range(q, end):
                        let target = d + i - q
                        for r in range(d):
                            let y = target - r
                            if y < d: c[i] = (c[i] + a[r] * b[y]) % 998244353
                else:
                    for i in range(q, end):
                        let target = d + i - q
                        for r in range(d):
                            let y = target - r
                            if y < 2 * d:
                                c[i] = (c[i] + a[q - d + r] * b[y] + b[q - d + r] * a[y]) % 998244353
            d *= 2
    for i in range(n):
        let bits = UInt64(c[i])
        for byte in range(4): output[4 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(4 * n)

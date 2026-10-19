from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fast_walsh_hadamard_transform")
fn fast_walsh_hadamard_transform(v: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130 or (v[0] != 0 and v[0] != 1) or v[1] < 1 or v[1] > 128: return -1
    let n = v[1]
    if (n & (n - 1)) != 0 or length != n + 2: return -1
    var a = InlineArray[Int64, 128](0)
    for i in range(n):
        if v[i + 2] < -10000 or v[i + 2] > 10000: return -1
        a[i] = v[i + 2]
    var h: Int64 = 1
    while h < n:
        var base: Int64 = 0
        while base < n:
            for j in range(h):
                let x = a[base + j]
                let y = a[base + j + h]
                a[base + j] = x + y
                a[base + j + h] = x - y
            base += 2 * h
        h *= 2
    if v[0] == 1:
        for i in range(n):
            if a[i] % n != 0: return -1
            a[i] /= n
    let bytes = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    for i in range(n):
        let bits = UInt64(a[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return n

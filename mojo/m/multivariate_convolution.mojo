from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MVC_MAX_K = 3
comptime MVC_MAX_P = 32
comptime MVC_MAX_INPUT = 69
comptime MVC_MAX_OUTPUT = 256
comptime MVC_MOD: Int64 = 998244353

@export("multivariate_convolution")
fn multivariate_convolution(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MVC_MAX_INPUT: return -1
    let count = Int(length); let k0 = input[0]
    if k0 < 0 or k0 > MVC_MAX_K: return -1
    let k = Int(k0)
    if count < 1 + k: return -1
    var dims = InlineArray[Int32, 3]()
    var p = 1
    for axis in range(k):
        let d0 = input[1 + axis]
        if d0 < 2 or d0 > MVC_MAX_P or p > MVC_MAX_P / Int(d0): return -1
        dims[axis] = Int32(d0); p *= Int(d0)
    let start = 1 + k
    if count != start + 2 * p: return -1
    for q in range(start, count):
        if input[q] < 0 or input[q] >= MVC_MOD: return -1
    let bytes = 8 * p
    if bytes > MVC_MAX_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    var a = InlineArray[Int64, 32](); var b = InlineArray[Int64, 32](); var result = InlineArray[Int64, 32]()
    for i in range(p): a[i] = input[start + i]; b[i] = input[start + p + i]
    for i in range(p):
        for j in range(p):
            var target = 0; var stride = 1; var valid = True
            for axis in range(k):
                let d = Int(dims[axis]); let total = (i / stride) % d + (j / stride) % d
                if total >= d: valid = False; break
                target += total * stride; stride *= d
            if valid: result[target] = (result[target] + a[i] * b[j]) % MVC_MOD
    for i in range(p):
        let bits = bitcast[UInt64](result[i])
        for byte in range(8): output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)

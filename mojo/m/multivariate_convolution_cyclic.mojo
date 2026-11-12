from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MVC_MAX_P = 32
comptime MVC_MAX_K = 3
comptime MVC_MAX_INPUT = 70
comptime MVC_MAX_OUTPUT = 256

fn mvc_is_prime(p: Int) -> Bool:
    if p < 2: return False
    var d = 2
    while d * d <= p:
        if p % d == 0: return False
        d += 1
    return True

@export("multivariate_convolution_cyclic")
fn multivariate_convolution_cyclic(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MVC_MAX_INPUT: return -1
    let count = Int(length); let p0 = input[0]; let k0 = input[1]
    if p0 < 2 or p0 > 97 or not mvc_is_prime(Int(p0)) or k0 < 0 or k0 > MVC_MAX_K: return -1
    let p = Int(p0); let k = Int(k0)
    if count < 2 + k: return -1
    var dims = InlineArray[Int32, 3](); var product = 1
    for axis in range(k):
        let d0 = input[2 + axis]
        if d0 < 2 or d0 > MVC_MAX_P or (p - 1) % Int(d0) != 0 or product > MVC_MAX_P / Int(d0): return -1
        dims[axis] = Int32(d0); product *= Int(d0)
    let start = 2 + k
    if count != start + 2 * product: return -1
    for q in range(start, count):
        if input[q] < 0 or input[q] >= p0: return -1
    let bytes = 8 * product
    if bytes > MVC_MAX_OUTPUT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    var a = InlineArray[Int64, 32](); var b = InlineArray[Int64, 32](); var result = InlineArray[Int64, 32]()
    for i in range(product): a[i] = input[start + i]; b[i] = input[start + product + i]
    for i in range(product):
        for j in range(product):
            var target = 0; var stride = 1
            for axis in range(k):
                let d = Int(dims[axis]); let total = ((i / stride) % d + (j / stride) % d) % d
                target += total * stride; stride *= d
            result[target] = (result[target] + a[i] * b[j]) % p0
    for i in range(product):
        let bits = bitcast[UInt64](result[i])
        for byte in range(8): output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("factorize")
fn factorize(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if value < 0 or value > 1000005: return -1
    var primes = InlineArray[UInt32, 10](0)
    var exponents = InlineArray[UInt32, 10](0)
    var count: Int64 = 0
    if value <= 1:
        primes[0] = UInt32(value)
        exponents[0] = 1
        count = 1
    else:
        var rem = value
        var d: Int64 = 2
        while d <= rem / d:
            if rem % d == 0:
                var exp: UInt32 = 0
                while rem % d == 0:
                    rem /= d
                    exp += 1
                primes[count] = UInt32(d)
                exponents[count] = exp
                count += 1
            d += 1
        if rem > 1:
            primes[count] = UInt32(rem)
            exponents[count] = 1
            count += 1
    let bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    for i in range(count):
        let p = primes[i]
        let e = exponents[i]
        for b in range(4):
            output[i * 8 + b] = UInt8((p >> (8 * b)) & 255)
            output[i * 8 + 4 + b] = UInt8((e >> (8 * b)) & 255)
    return bytes

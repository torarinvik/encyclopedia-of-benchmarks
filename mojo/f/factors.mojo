from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("factors")
fn factors(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if value < 1 or value > 256: return -1
    var divisors = InlineArray[Int64, 256](0)
    var count: Int64 = 0
    var required: Int64 = 0
    for d in range(1, value + 1):
        if value % d == 0:
            divisors[count] = d
            count += 1
            var temp = d
            var digits: Int64 = 1
            while temp >= 10:
                temp /= 10
                digits += 1
            required += digits
            if count > 1: required += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var pos: Int64 = 0
    for i in range(count):
        if i > 0:
            output[pos] = 44
            pos += 1
        var d = divisors[i]
        var digits = InlineArray[UInt8, 3](0)
        var len: Int64 = 0
        while d > 0:
            digits[len] = UInt8(d % 10)
            len += 1
            d /= 10
        while len > 0:
            len -= 1
            output[pos] = 48 + digits[len]
            pos += 1
    return pos

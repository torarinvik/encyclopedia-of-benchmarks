from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("factorial_large_number")
fn factorial_large_number(n: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if n < 0 or n > 100: return -1
    var digits = InlineArray[Int64, 160](0)
    digits[0] = 1
    var count: Int64 = 1
    for factor in range(2, n + 1):
        var carry: Int64 = 0
        for i in range(count):
            let product = digits[i] * factor + carry
            digits[i] = product % 10
            carry = product / 10
        while carry != 0:
            digits[count] = carry % 10
            count += 1
            carry /= 10
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < count: return -2
    for i in range(count): output[i] = UInt8(48 + digits[count - i - 1])
    return count

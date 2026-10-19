from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("add_two_numbers")
fn add_two_numbers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 2050:
        return -1
    let n1 = input[0]
    let n2 = input[1]
    if n1 < 0 or n1 > 1024 or n2 < 0 or n2 > 1024 or length != c_size_t(2 + n1 + n2):
        return -1
    for i in range(n1 + n2):
        if input[2 + i] < 0 or input[2 + i] > 9:
            return -1
    var digits = List[UInt8](capacity=1025)
    var carry: Int64 = 0
    var width = n1
    if n2 > width:
        width = n2
    var i: Int64 = 0
    while i < width or carry != 0:
        var a: Int64 = 0
        var b: Int64 = 0
        if i < n1:
            a = input[2 + i]
        if i < n2:
            b = input[2 + n1 + i]
        let total = a + b + carry
        digits.append(UInt8(total % 10))
        carry = total / 10
        i += 1
    if capacity < c_size_t(len(digits)) or (len(digits) > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    for j in range(len(digits)):
        output[j] = digits[j]
    return Int64(len(digits))

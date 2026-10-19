from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_to_octal")
fn binary_to_octal(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 63: return -1
    var value: Int64 = 0
    for i in range(Int(length)):
        let bit = input[i]
        if bit != 0 and bit != 1: return -1
        value = value * 2 + bit
    var count = 1; var tmp = value
    while tmp >= 8: tmp //= 8; count += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    var reverse = List[UInt8](capacity=count); tmp = value
    while tmp > 0: reverse.append(UInt8(48 + (tmp % 8))); tmp //= 8
    if value == 0: reverse.append(48)
    for i in range(count): output[i] = reverse[count - i - 1]
    return Int64(count)

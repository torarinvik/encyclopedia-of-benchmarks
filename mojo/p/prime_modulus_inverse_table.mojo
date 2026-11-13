from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("prime_modulus_inverse_table")
fn prime_modulus_inverse_table(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34: return -1
    let count_value = input[0]
    if count_value < 0 or count_value > 32: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    var maximum = 0
    for i in range(count):
        let operand = input[i + 1]
        if operand < 1 or operand > 256: return -1
        if Int(operand) > maximum: maximum = Int(operand)
    if count == 0: return 0
    let bytes = 4 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    let modulus = Int64(1000000007)
    var inverse = List[Int64](capacity=257)
    for _ in range(257): inverse.append(0)
    inverse[1] = 1
    for i in range(2, maximum + 1):
        let value = Int64(i)
        inverse[i] = modulus - (modulus // value) * inverse[Int(modulus % value)] % modulus
    for i in range(count):
        let value = UInt32(inverse[Int(input[i + 1])])
        output[4*i] = UInt8(value & 255)
        output[4*i+1] = UInt8((value >> 8) & 255)
        output[4*i+2] = UInt8((value >> 16) & 255)
        output[4*i+3] = UInt8((value >> 24) & 255)
    return Int64(bytes)

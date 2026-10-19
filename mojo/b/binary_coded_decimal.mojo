from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_coded_decimal")
fn binary_coded_decimal(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if value < -2_147_483_648 or value > 2_147_483_647: return -1
    var number = max(value, Int64(0))
    var digits = List[Int](capacity=10)
    if number == 0: digits.append(0)
    while number > 0:
        digits.append(Int(number % 10)); number //= 10
    let required = 2 + 4 * len(digits)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var bytes = List[UInt8](capacity=required); bytes.append(UInt8(48)); bytes.append(UInt8(98))
    for i in range(len(digits) - 1, -1, -1):
        for bit in range(3, -1, -1): bytes.append(UInt8(48 + ((digits[i] >> bit) & 1)))
    for i in range(required): output[i] = bytes[i]
    return Int64(required)

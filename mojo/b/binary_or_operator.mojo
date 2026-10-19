from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_or_operator")
fn binary_or_operator(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let a = input[0]; let b = input[1]
    if a < 0 or a > 2_147_483_647 or b < 0 or b > 2_147_483_647: return -1
    var largest = max(a, b); var width = 0
    while largest > 0: width += 1; largest >>= 1
    width = max(1, width); let needed = width + 2
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var bytes = List[UInt8](capacity=needed); bytes.append(48); bytes.append(98)
    let value = a | b
    for i in range(width): bytes.append(UInt8(49) if ((value >> (width - 1 - i)) & 1) != 0 else UInt8(48))
    for i in range(needed): output[i] = bytes[i]
    return Int64(needed)

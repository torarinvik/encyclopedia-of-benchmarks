from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("base_neg2_conversion")
fn base_neg2_conversion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    var value = input[0]
    var reversed = List[UInt8](capacity=64)
    if value == 0:
        reversed.append(UInt8(48))
    else:
        while value != 0:
            var remainder = value % -2
            value /= -2
            if remainder < 0:
                remainder += 2
                value += 1
            reversed.append(UInt8(48 + remainder))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(reversed)): return -2
    for i in range(len(reversed)):
        output[i] = reversed[len(reversed) - 1 - i]
    return Int64(len(reversed))

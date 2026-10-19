from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("any_base_to_any_base")
fn any_base_to_any_base(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 65:
        return -1
    let source_base = input[0]
    let target_base = input[1]
    if source_base < 2 or source_base > 36 or target_base < 2 or target_base > 36:
        return -1
    var value: Int64 = 0
    for i in range(2, Int(length)):
        let digit = input[i]
        if digit < 0 or digit >= source_base or value > (Int64.max - digit) / source_base:
            return -1
        value = value * source_base + digit
    var reversed = List[UInt8](capacity=64)
    var rest = value
    if rest == 0:
        reversed.append(48)
    while rest > 0:
        let digit = rest % target_base
        if digit < 10:
            reversed.append(UInt8(48 + digit))
        else:
            reversed.append(UInt8(65 + digit - 10))
        rest /= target_base
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(reversed)):
        return -2
    for i in range(len(reversed)):
        output[i] = reversed[len(reversed) - i - 1]
    return Int64(len(reversed))

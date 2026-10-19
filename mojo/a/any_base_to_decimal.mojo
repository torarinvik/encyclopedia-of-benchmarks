from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("any_base_to_decimal")
fn any_base_to_decimal(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65:
        return -1
    let base = input[0]
    if base < 2 or base > 36:
        return -1
    var value: Int64 = 0
    for i in range(1, Int(length)):
        let digit = input[i]
        if digit < 0 or digit >= base or value > (Int64.max - digit) / base:
            return -1
        value = value * base + digit
    return value

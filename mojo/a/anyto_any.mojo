from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("anyto_any")
fn anyto_any(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    var encoded = input[0]
    let source_base = input[1]
    let destination_base = input[2]
    if encoded < 0 or encoded > 999999999 or source_base < 2 or source_base > 10 or destination_base < 2 or destination_base > 10:
        return -1
    var decimal_value: Int64 = 0
    var source_multiplier: Int64 = 1
    while encoded > 0:
        let digit = encoded % 10
        if digit >= source_base:
            return -1
        decimal_value += digit * source_multiplier
        source_multiplier *= source_base
        encoded /= 10
    var result: Int64 = 0
    var destination_multiplier: Int64 = 1
    while decimal_value > 0:
        let digit = decimal_value % destination_base
        result += digit * destination_multiplier
        decimal_value /= destination_base
        if decimal_value > 0:
            if destination_multiplier > 999999999 / 10:
                return -1
            destination_multiplier *= 10
    return result

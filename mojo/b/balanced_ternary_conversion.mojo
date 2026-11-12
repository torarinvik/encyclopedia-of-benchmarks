from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_OUTPUT_BYTES = 41

@export("balanced_ternary_conversion")
fn balanced_ternary_conversion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    var reversed = InlineArray[UInt8, MAX_OUTPUT_BYTES]()
    var digit_count = 0
    var value = input[0]
    if value == 0:
        reversed[digit_count] = UInt8(48)
        digit_count += 1
    while value != 0:
        var quotient = value / 3
        let remainder = value % 3
        var digit = UInt8(49)
        if remainder == 2:
            digit = UInt8(90)
            quotient += 1
        elif remainder == -2:
            digit = UInt8(49)
            quotient -= 1
        elif remainder == -1:
            digit = UInt8(90)
        elif remainder == 0:
            digit = UInt8(48)
        reversed[digit_count] = digit
        digit_count += 1
        value = quotient
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < digit_count:
        return -2
    for index in range(digit_count):
        output[index] = reversed[digit_count - index - 1]
    return Int64(digit_count)

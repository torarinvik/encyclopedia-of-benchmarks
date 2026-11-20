from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_BITS = 4096
alias MAX_INPUT_LENGTH = MAX_BITS + 2

@export("binary_divisibility_by_three_dfa")
fn binary_divisibility_by_three_dfa(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > MAX_INPUT_LENGTH:
        return -1
    let bit_count = input[0]
    if bit_count < 1 or bit_count > MAX_BITS or length != c_size_t(bit_count + 1):
        return -1
    var remainder: Int64 = 0
    for index in range(1, Int(length)):
        if input[index] != 0 and input[index] != 1: return -1
        remainder = (2 * remainder + input[index]) % 3
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 1: return -2

    output[0] = UInt8(1 if remainder == 0 else 0)
    return 1

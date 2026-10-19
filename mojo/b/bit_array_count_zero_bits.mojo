from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("bit_array_count_zero_bits")
fn bit_array_count_zero_bits(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var zeros: Int64 = 0
    for i in range(Int(length)):
        if input[i] != 0 and input[i] != 1: return -1
        if input[i] == 0: zeros += 1
    return zeros

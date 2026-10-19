from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn is_ascii_space(value: Int64) -> Bool:
    return (value >= 9 and value <= 13) or value == 32

@export("c_atoi_str_to_integer")
fn c_atoi_str_to_integer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    for i in range(length):
        if input[i] < 0 or input[i] > 127: return -2
    var i: Int64 = 0
    while i < length and input[i] != 0 and is_ascii_space(input[i]): i += 1
    var negative = False
    if i < length and input[i] != 0 and (input[i] == 43 or input[i] == 45):
        negative = input[i] == 45
        i += 1
    let limit: Int64 = 2147483647 if not negative else 2147483648
    var magnitude: Int64 = 0
    while i < length and input[i] != 0 and input[i] >= 48 and input[i] <= 57:
        let digit = input[i] - 48
        if magnitude > limit // 10 or (magnitude == limit // 10 and digit > limit % 10):
            return -2147483648 if negative else 2147483647
        magnitude = magnitude * 10 + digit
        i += 1
    return -magnitude if negative else magnitude

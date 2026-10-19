from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ascii_lower(value: Int64) -> Int64:
    if value >= 65 and value <= 90: return value + 32
    return value

@export("case_insensitive_palindrome")
fn case_insensitive_palindrome(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < 0 or values[i] > 127: return -1
    for i in range(length // 2):
        if ascii_lower(values[i]) != ascii_lower(values[length - 1 - i]): return 0
    return 1

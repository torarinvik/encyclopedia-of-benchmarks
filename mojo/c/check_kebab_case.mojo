from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn is_ascii_word(value: Int64) -> Bool:
    return (value >= 97 and value <= 122) or (value >= 65 and value <= 90) or (value >= 48 and value <= 57)

@export("check_kebab_case")
fn check_kebab_case(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -2
    for i in range(length):
        if values[i] == 95: return 0
    if length > 2:
        for i in range(1, length - 1):
            if values[i] == 45 and is_ascii_word(values[i - 1]) and is_ascii_word(values[i + 1]): return 1
    return 0

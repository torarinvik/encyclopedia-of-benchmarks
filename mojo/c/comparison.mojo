from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn comparison_fold(value: Int64, mode: Int64) -> Int64:
    return value + 32 if mode == 1 and value >= 65 and value <= 90 else value

@export("comparison")
fn comparison(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 131: return -2
    let mode = values[0]
    let n1 = values[1]
    if (mode != 0 and mode != 1) or n1 < 0 or n1 > 64: return -2
    let second_pos = 2 + n1
    if second_pos >= length: return -2
    let n2 = values[second_pos]
    if n2 < 0 or n2 > 64 or second_pos + 1 + n2 != length: return -2
    for i in range(n1):
        if values[2 + i] < 1 or values[2 + i] > 127: return -2
    for i in range(n2):
        if values[second_pos + 1 + i] < 1 or values[second_pos + 1 + i] > 127: return -2
    let common = n1 if n1 < n2 else n2
    for i in range(common):
        let a = comparison_fold(values[2 + i], mode)
        let b = comparison_fold(values[second_pos + 1 + i], mode)
        if a < b: return -1
        if a > b: return 1
    if n1 < n2: return -1
    if n1 > n2: return 1
    return 0

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("checkequal")
fn checkequal(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 2053: return -1
    let rows_a = values[0]
    let columns_a = values[1]
    let rows_b = values[2]
    let columns_b = values[3]
    if rows_a < 0 or rows_a > 32 or columns_a < 0 or columns_a > 32 or rows_b < 0 or rows_b > 32 or columns_b < 0 or columns_b > 32: return -1
    let count_a = rows_a * columns_a
    let count_b = rows_b * columns_b
    if length != 4 + count_a + count_b: return -1
    if rows_a != rows_b or columns_a != columns_b: return 0
    for i in range(count_a):
        if values[4 + i] != values[4 + count_a + i]: return 0
    return 1

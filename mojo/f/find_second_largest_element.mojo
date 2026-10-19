from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_second_largest_element")
fn find_second_largest_element(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 10001: return -9223372036854775808
    let n = input[0]
    if n < 2 or n > 10000 or length != n + 1: return -9223372036854775808
    var largest: Int64 = -2147483648
    for i in range(n):
        let value = input[i + 1]
        if value < -2147483648 or value > 2147483647: return -9223372036854775808
        if value > largest: largest = value
    var second: Int64 = -2147483649
    for i in range(n):
        let value = input[i + 1]
        if value < largest and value > second: second = value
    return -9223372036854775808 if second == -2147483649 else second

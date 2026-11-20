from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("binomial_divisibility_primality_test")
fn binomial_divisibility_primality_test(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let n_value = input[0]
    if n_value < 2 or n_value > 1000:
        return -1
    let n = Int(n_value)

    var row = InlineArray[Int64, 1001](fill=0)
    row[0] = 1
    var degree = 1
    while degree <= n:
        row[degree] = 1
        var index = degree - 1
        while index > 0:
            row[index] = (row[index] + row[index - 1]) % n_value
            index -= 1
        degree += 1
    var index = 1
    while index < n:
        if row[index] != 0:
            return 0
        index += 1
    return 1

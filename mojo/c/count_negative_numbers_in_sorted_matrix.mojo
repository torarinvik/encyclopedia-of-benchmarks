from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_negative_numbers_in_sorted_matrix")
fn count_negative_numbers_in_sorted_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 514: return -1
    let rows = input[0]
    let columns = input[1]
    if rows < 1 or rows > 512 or columns < 1 or columns > 512 or rows * columns > 512 or length != 2 + rows * columns: return -1
    var nonnegative: Int64 = 0
    var bound = columns
    for row in range(rows):
        var left: Int64 = 0
        var right = bound
        while left < right:
            let middle = left + (right - left) / 2
            if input[2 + row * columns + middle] >= 0: left = middle + 1
            else: right = middle
        bound = left
        nonnegative += bound
    return rows * columns - nonnegative

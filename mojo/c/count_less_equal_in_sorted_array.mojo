from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_less_equal_in_sorted_array")
fn count_less_equal_in_sorted_array(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 513: return -1
    let key = input[0]
    if key < -2147483648 or key > 2147483647: return -1
    for index in range(1, length):
        let value = input[index]
        if value < -2147483648 or value > 2147483647 or (index > 1 and input[index - 1] > value): return -1
    var left: Int64 = 1
    var right = Int64(length) - 1
    var count: Int64 = 0
    while left <= right:
        let middle = left + (right - left) / 2
        if input[middle] > key: right = middle - 1
        else:
            count = middle
            left = middle + 1
    return count

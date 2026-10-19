from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bst_from_sorted_array_shape(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, end: Int, heap_index: Int) -> Int64:
    if start >= end:
        return 0
    let middle = start + (end - start - 1) // 2
    let here = Int64(1) << heap_index
    return here | bst_from_sorted_array_shape(input, start, middle, 2 * heap_index + 1) | bst_from_sorted_array_shape(input, middle + 1, end, 2 * heap_index + 2)

@export("bst_from_sorted_array")
fn bst_from_sorted_array(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 15:
        return -1
    let count = Int(length)
    if count == 0:
        return 0
    if input == UnsafePointer[Int64, ImmutAnyOrigin]():
        return -1
    for index in range(count):
        let value = input[index]
        if value < -2147483648 or value > 2147483647:
            return -1
        if index > 0 and input[index - 1] >= value:
            return -1
    return bst_from_sorted_array_shape(input, 0, count, 0)

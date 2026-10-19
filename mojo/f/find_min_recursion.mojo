from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn find_min_rec_range(values: UnsafePointer[Int64, ImmutAnyOrigin], low: Int64, high: Int64) -> Int64:
    if low == high: return values[low]
    let middle = low + (high - low) / 2
    let left = find_min_rec_range(values, low, middle)
    let right = find_min_rec_range(values, middle + 1, high)
    return left if left <= right else right

@export("find_min_recursion")
fn find_min_recursion(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 256: return -1
    for i in range(length):
        if values[i] < -2147483648 or values[i] > 2147483647: return -1
    return find_min_rec_range(values, 0, Int64(length) - 1)

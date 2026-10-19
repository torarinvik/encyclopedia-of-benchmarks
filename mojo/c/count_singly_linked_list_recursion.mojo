from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn count_list_nodes(values: UnsafePointer[Int64, ImmutAnyOrigin], remaining: Int64) -> Int64:
    if remaining == 0: return 0
    let value = values[0]
    if value < -2147483648 or value > 2147483647: return -1
    let tail = count_list_nodes(values + 1, remaining - 1)
    return -1 if tail < 0 else tail + 1

@export("count_singly_linked_list_recursion")
fn count_singly_linked_list_recursion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let n = input[0]
    if n < 0 or n > 64 or length != n + 1: return -1
    return count_list_nodes(input + 1, n)

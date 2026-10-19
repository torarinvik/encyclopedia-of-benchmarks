from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_duplicate_number")
fn find_duplicate_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 100001: return -1
    let max_value = Int64(length) - 1
    for i in range(length):
        if values[i] < 1 or values[i] > max_value: return -1
    var slow = values[0]
    var fast = values[0]
    while True:
        slow = values[slow]
        fast = values[values[fast]]
        if slow == fast: break
    slow = values[0]
    while slow != fast:
        slow = values[slow]
        fast = values[fast]
    return slow

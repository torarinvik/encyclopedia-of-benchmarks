from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MISSING_NODE: Int64 = -2_147_483_649
@export("binary_tree_is_sorted_local")
fn binary_tree_is_sorted_local(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 255: return -1
    if input[0] == MISSING_NODE: return -1
    for i in range(Int(length)):
        let value = input[i]
        if value == MISSING_NODE: continue
        if value < -2_147_483_648 or value > 2_147_483_647: return -1
        if i > 0:
            let parent = (i - 1) // 2
            if input[parent] == MISSING_NODE: return -1
            if (i % 2 == 1 and value > input[parent]) or (i % 2 == 0 and value < input[parent]): return 0
    return 1

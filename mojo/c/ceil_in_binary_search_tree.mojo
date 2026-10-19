from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime NO_CEIL: Int64 = -9223372036854775808
comptime INVALID: Int64 = -9223372036854775807

@export("ceil_in_binary_search_tree")
fn ceil_in_binary_search_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 384: return INVALID
    let node_count = input[0]
    let root_index = input[1]
    let key = input[2]
    if node_count < 0 or node_count > 127 or key < -1000000 or key > 1000000 or length != 3 + 3 * node_count: return INVALID
    if node_count == 0: return NO_CEIL if root_index == -1 else INVALID
    if root_index < 0 or root_index >= node_count: return INVALID
    var current = root_index
    var best = NO_CEIL
    var steps: Int64 = 0
    while current >= 0:
        if steps >= node_count: return INVALID
        steps += 1
        let offset = 3 + 3 * current
        let value = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        if value < -1000000 or value > 1000000 or left < -1 or right < -1 or left >= node_count or right >= node_count: return INVALID
        if value == key: return value
        if value < key: current = right
        else:
            best = value
            current = left
    return best

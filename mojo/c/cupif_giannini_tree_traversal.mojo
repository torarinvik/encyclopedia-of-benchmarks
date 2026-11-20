from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cupif_giannini_tree_traversal")
fn cupif_giannini_tree_traversal(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 3: return -1
    if length != 2: return -1

    let height_value = input[0]
    let key_value = input[1]
    if height_value < 0 or height_value > 6: return -1
    let height = Int(height_value)
    let leaf_count = 1 << height
    if key_value < 0 or key_value >= Int64(leaf_count): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(leaf_count): return -2

    for count in range(leaf_count):
        let path = UInt64(count) ^ UInt64(key_value)
        var leaf_code = UInt8(0)
        for depth in range(height):
            if ((path >> depth) & 1) != 0:
                leaf_code = leaf_code | (UInt8(1) << depth)
        output[count] = leaf_code
    return Int64(leaf_count)

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("find_all_duplicates_hash_order")
fn find_all_duplicates_hash_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var keys = InlineArray[Int64, 2048](0)
    var counts = InlineArray[Int64, 2048](0)
    var used = InlineArray[Bool, 2048](False)
    var insertion = InlineArray[Int64, 1024](0)
    var unique: Int64 = 0
    for i in range(length):
        var remainder = input[i] % 2048
        if remainder < 0: remainder += 2048
        var slot = remainder
        while used[slot] and keys[slot] != input[i]: slot = (slot + 1) & 2047
        if not used[slot]:
            used[slot] = True
            keys[slot] = input[i]
            counts[slot] = 1
            insertion[unique] = slot
            unique += 1
        else: counts[slot] += 1
    var duplicates: Int64 = 0
    for i in range(unique):
        if counts[insertion[i]] > 1: duplicates += 1
    let bytes = duplicates * 8
    if capacity < bytes or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var stage = InlineArray[Int64, 1024](0)
    var out_count: Int64 = 0
    for i in range(unique):
        let slot = insertion[i]
        if counts[slot] > 1:
            stage[out_count] = keys[slot]
            out_count += 1
    for i in range(duplicates):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return duplicates

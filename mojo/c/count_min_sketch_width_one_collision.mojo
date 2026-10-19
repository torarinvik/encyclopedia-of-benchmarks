from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("count_min_sketch_width_one_collision")
fn count_min_sketch_width_one_collision(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 513: return -1
    let count = input[0]
    if count < 0 or count > 256 or length != 1 + count * 2: return -1
    var queries: Int64 = 0
    for i in range(count):
        let operation = input[1 + 2 * i]
        let key = input[2 + 2 * i]
        if (operation != 0 and operation != 1) or key < -1000000 or key > 1000000: return -1
        if operation == 1: queries += 1
    let required = queries * 8
    if capacity < required or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var inserts: Int64 = 0
    var result_index: Int64 = 0
    var estimates = InlineArray[Int64, 256](0)
    for i in range(count):
        if input[1 + 2 * i] == 0: inserts += 1
        else:
            estimates[result_index] = inserts
            result_index += 1
    for i in range(queries):
        let bits = UInt64(estimates[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return required

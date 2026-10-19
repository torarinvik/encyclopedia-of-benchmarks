from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("combination_sum")
fn combination_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let count = input[0]
    let target = input[1]
    if count < 1 or count > 8 or target < 0 or target > 20 or length != count + 2: return -1
    for i in range(count):
        if input[i + 2] < 1 or input[i + 2] > 24 or (i > 0 and input[i + 1] >= input[i + 2]): return -1
    var packed = InlineArray[Int64, 4096](0)
    var path = InlineArray[Int64, 20](0)
    var next_index = InlineArray[Int64, 21](0)
    var remaining = InlineArray[Int64, 21](0)
    var used: Int64 = 1
    var combo_count: Int64 = 0
    var depth: Int64 = 0
    remaining[0] = target
    while depth >= 0:
        if remaining[depth] == 0:
            packed[used] = depth
            used += 1
            for i in range(depth):
                packed[used] = path[i]
                used += 1
            combo_count += 1
            depth -= 1
            if depth >= 0: next_index[depth] += 1
            continue
        let candidate_index = next_index[depth]
        if candidate_index >= count or input[2 + candidate_index] > remaining[depth]:
            depth -= 1
            if depth >= 0: next_index[depth] += 1
            continue
        let chosen = input[2 + candidate_index]
        path[depth] = chosen
        let child_depth = depth + 1
        remaining[child_depth] = remaining[depth] - chosen
        next_index[child_depth] = candidate_index
        depth = child_depth
    packed[0] = combo_count
    let required = used * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    for i in range(used):
        let bits = UInt64(packed[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return required

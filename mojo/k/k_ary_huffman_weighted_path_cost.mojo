from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


@export("k_ary_huffman_weighted_path_cost")
fn k_ary_huffman_weighted_path_cost(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 13:
        return -1
    let arity_value = input[0]
    let count_value = input[1]
    if (arity_value != 3 and arity_value != 4) or count_value < 1 or count_value > 10:
        return -1
    let arity = Int(arity_value)
    let count = Int(count_value)
    if length != c_size_t(count + 2) or (count > 1 and (count - 1) % (arity - 1) != 0):
        return -1

    var weights = InlineArray[Int64, 16]()
    var active = InlineArray[Bool, 16]()
    for index in range(count):
        let weight = input[index + 2]
        if weight < 0 or weight > 1000:
            return -1
        weights[index] = weight
        active[index] = True

    var node_count = count
    var active_count = count
    var cost = Int64(0)
    while active_count > 1:
        var combined = Int64(0)
        for pick in range(arity):
            var best = -1
            for index in range(node_count):
                if not active[index]:
                    continue
                if best == -1:
                    best = index
                elif weights[index] < weights[best] or (weights[index] == weights[best] and index < best):
                    best = index
            if best == -1:
                return -1
            combined += weights[best]
            active[best] = False
            active_count -= 1
        cost += combined
        weights[node_count] = combined
        active[node_count] = True
        node_count += 1
        active_count += 1
    return cost

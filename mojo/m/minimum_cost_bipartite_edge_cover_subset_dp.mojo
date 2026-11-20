from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime INF = Int64(1) << 60
comptime MAX_STATES = 256

@export("minimum_cost_bipartite_edge_cover_subset_dp")
fn minimum_cost_bipartite_edge_cover_subset_dp(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 67: return -1
    let left_value = input[0]
    let right_value = input[1]
    if left_value < 1 or left_value > 8 or right_value < 1 or right_value > 8: return -1
    let left_count = Int(left_value)
    let right_count = Int(right_value)
    if length != c_size_t(2 + left_count * right_count): return -1
    for edge in range(left_count * right_count):
        let cost = input[2 + edge]
        if cost < 0 or cost > 1000: return -1

    let states = 1 << right_count
    var current = InlineArray[Int64, MAX_STATES](fill=INF)
    var following = InlineArray[Int64, MAX_STATES](fill=INF)
    var subset_cost = InlineArray[Int64, MAX_STATES](fill=0)
    current[0] = 0
    for left in range(left_count):
        subset_cost[0] = 0
        for subset in range(1, states):
            let low_bit = subset & -subset
            var bit_position = 0
            var scan = low_bit
            while scan > 1:
                scan >>= 1
                bit_position += 1
            subset_cost[subset] = subset_cost[subset ^ low_bit] + input[2 + left * right_count + bit_position]
        for mask in range(states): following[mask] = INF
        for covered in range(states):
            if current[covered] == INF: continue
            for selected in range(1, states):
                let combined = covered | selected
                let candidate = current[covered] + subset_cost[selected]
                if candidate < following[combined]: following[combined] = candidate
        current = following
    return current[states - 1]

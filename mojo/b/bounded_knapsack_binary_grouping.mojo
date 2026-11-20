from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TYPES = 16
comptime MAX_CAPACITY = 64
comptime MAX_INPUT = 51

@export("bounded_knapsack_binary_grouping")
fn bounded_knapsack_binary_grouping(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_INPUT):
        return -1
    let type_count = Int(input[0])
    let capacity = Int(input[1])
    if type_count < 0 or type_count > MAX_TYPES or capacity < 0 or capacity > MAX_CAPACITY:
        return -1
    if Int(length) != 2 + 3 * type_count:
        return -1
    for item in range(type_count):
        let weight = Int(input[2 + 3 * item])
        let value = Int(input[3 + 3 * item])
        let count = Int(input[4 + 3 * item])
        if weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16:
            return -1

    var best = InlineArray[Int64, 65](fill=0)
    for item in range(type_count):
        let weight = Int(input[2 + 3 * item])
        let value = input[3 + 3 * item]
        var remaining = Int(input[4 + 3 * item])
        var bundle_size = 1
        while remaining > 0:
            let copies = min(bundle_size, remaining)
            let bundle_weight = weight * copies
            let bundle_value = value * Int64(copies)
            if bundle_weight <= capacity:
                var limit = capacity
                while limit >= bundle_weight:
                    let candidate = best[limit - bundle_weight] + bundle_value
                    best[limit] = max(best[limit], candidate)
                    if limit == bundle_weight:
                        break
                    limit -= 1
            remaining -= copies
            bundle_size *= 2
    return best[capacity]

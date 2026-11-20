from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TYPES = 16
comptime MAX_CAPACITY = 64
comptime MAX_INPUT = 67

@export("mixed_knapsack")
fn mixed_knapsack(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_INPUT):
        return -1
    let type_count = Int(input[0])
    let capacity = Int(input[1])
    if type_count < 0 or type_count > MAX_TYPES or capacity < 0 or capacity > MAX_CAPACITY:
        return -1
    if Int(length) != 2 + 4 * type_count:
        return -1
    for item in range(type_count):
        let mode = Int(input[2 + 4 * item])
        let weight = Int(input[3 + 4 * item])
        let value = Int(input[4 + 4 * item])
        let limit = Int(input[5 + 4 * item])
        if mode < 0 or mode > 2 or weight < 1 or weight > 16 or value < 0 or value > 100:
            return -1
        if (mode == 0 and limit != 1) or (mode == 1 and limit != 0) or (mode == 2 and (limit < 0 or limit > 16)):
            return -1

    var best = InlineArray[Int64, 65](fill=0)
    for item in range(type_count):
        let mode = Int(input[2 + 4 * item])
        let weight = Int(input[3 + 4 * item])
        let value = input[4 + 4 * item]
        if mode == 0:
            var cap = capacity
            while cap >= weight:
                let candidate = best[cap - weight] + value
                best[cap] = max(best[cap], candidate)
                if cap == weight:
                    break
                cap -= 1
        elif mode == 1:
            for cap in range(weight, capacity + 1):
                let candidate = best[cap - weight] + value
                best[cap] = max(best[cap], candidate)
        else:
            var remaining = Int(input[5 + 4 * item])
            var bundle_size = 1
            while remaining > 0:
                let copies = min(bundle_size, remaining)
                let bundle_weight = copies * weight
                let bundle_value = Int64(copies) * value
                if bundle_weight <= capacity:
                    var cap = capacity
                    while cap >= bundle_weight:
                        let candidate = best[cap - bundle_weight] + bundle_value
                        best[cap] = max(best[cap], candidate)
                        if cap == bundle_weight:
                            break
                        cap -= 1
                remaining -= copies
                bundle_size *= 2
    return best[capacity]

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_ITEMS = 32
comptime MAX_TARGET = 256
comptime MAX_WEIGHT = 12
comptime MAX_PARSEABLE_INPUT_LENGTH = 35
comptime MAX_STATES = 2 * MAX_WEIGHT

@export("pisinger_bounded_weight_subset_sum")
fn pisinger_bounded_weight_subset_sum(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if (input == UnsafePointer[Int64, ImmutAnyOrigin]() or
            length < c_size_t(2) or length > c_size_t(MAX_PARSEABLE_INPUT_LENGTH)):
        return -1
    let n = Int(input[0])
    let target_value = Int(input[1])
    if n < 0 or n > MAX_ITEMS or target_value < 0 or target_value > MAX_TARGET:
        return -1
    if Int(length) != n + 2:
        return -1

    var width = 0
    for index in range(n):
        let weight = Int(input[2 + index])
        if weight < 1 or weight > MAX_WEIGHT:
            return -1
        width = max(width, weight)
    if n == 0:
        return 0

    var prefix_sum = 0
    var break_index = 0
    while break_index < n and prefix_sum + Int(input[2 + break_index]) <= target_value:
        prefix_sum += Int(input[2 + break_index])
        break_index += 1
    if break_index == n:
        return Int64(prefix_sum)

    var previous = InlineArray[Int, MAX_STATES](fill=-1)
    var current = InlineArray[Int, MAX_STATES](fill=-1)
    previous[prefix_sum + width - target_value - 1] = break_index
    for item in range(break_index, n):
        for slot in range(2 * width):
            current[slot] = previous[slot]
        let weight = Int(input[2 + item])
        for slot in range(width):
            let destination = slot + weight
            current[destination] = max(current[destination], previous[slot])
        for slot in range(2 * width - 1, width - 1, -1):
            let first_item = max(0, previous[slot])
            let stop_item = current[slot]
            for removed in range(first_item, stop_item):
                let reduced = slot - Int(input[2 + removed])
                current[reduced] = max(current[reduced], removed)
        for slot in range(2 * width):
            previous[slot] = current[slot]

    let low = max(0, target_value - width + 1)
    var mass = target_value
    while mass >= low:
        if previous[mass + width - target_value - 1] >= 0:
            return Int64(mass)
        if mass == 0:
            break
        mass -= 1
    return 0

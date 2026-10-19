from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn brute_force_knapsack_value(input: UnsafePointer[Int64, ImmutAnyOrigin], item_count: Int, capacity: Int64) -> Int64:
    if item_count == 0 or capacity == 0:
        return 0
    let weight = input[2 + 2 * (item_count - 1)]
    let value = input[3 + 2 * (item_count - 1)]
    if weight > capacity:
        return brute_force_knapsack_value(input, item_count - 1, capacity)
    let excluded = brute_force_knapsack_value(input, item_count - 1, capacity)
    let included = value + brute_force_knapsack_value(input, item_count - 1, capacity - weight)
    return excluded if excluded > included else included

@export("brute_force_knapsack")
fn brute_force_knapsack(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let capacity = input[0]
    let item_count = input[1]
    if capacity < 0 or capacity > 512 or item_count < 0 or item_count > 14:
        return -1
    if length != c_size_t(2 + 2 * item_count):
        return -1
    for index in range(Int(item_count)):
        let weight = input[2 + 2 * index]
        let value = input[3 + 2 * index]
        if weight < 1 or weight > 4096 or value < 0 or value > 100000000:
            return -1
    return brute_force_knapsack_value(input, Int(item_count), capacity)

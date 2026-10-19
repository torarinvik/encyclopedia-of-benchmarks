from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_CAPACITY = 512
comptime MAX_ITEMS = 16
comptime MAX_WEIGHT = 4096
comptime MAX_VALUE = 1_000_000_000


fn solve_recursive(
    packed: UnsafePointer[Int64, ImmutAnyOrigin], item_count: Int64, capacity: Int64
) -> Int64:
    if item_count == 0 or capacity == 0:
        return 0
    let offset = 2 + 2 * (item_count - 1)
    let weight = packed[offset]
    let value = packed[offset + 1]
    if weight <= capacity:
        let take = value + solve_recursive(packed, item_count - 1, capacity - weight)
        let skip = solve_recursive(packed, item_count - 1, capacity)
        return max(take, skip)
    return solve_recursive(packed, item_count - 1, capacity)


@export("knapsack_01_recursive_benchmark")
fn knapsack_01_recursive_benchmark(
    packed: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if packed == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 34:
        return -1
    let capacity = packed[0]
    let item_count = packed[1]
    if (
        capacity < 0
        or capacity > MAX_CAPACITY
        or item_count < 0
        or item_count > MAX_ITEMS
        or length != c_size_t(2 + 2 * item_count)
    ):
        return -1
    for item in range(item_count):
        let offset = 2 + 2 * item
        let weight = packed[offset]
        let value = packed[offset + 1]
        if weight < 1 or weight > MAX_WEIGHT or value < 0 or value > MAX_VALUE:
            return -1
    return solve_recursive(packed, item_count, capacity)

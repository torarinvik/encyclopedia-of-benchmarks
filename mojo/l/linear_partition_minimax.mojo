from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_PARSEABLE_INPUT_LENGTH = 35

fn lpm_feasible(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
                groups: Int, limit: Int64) -> Bool:
    var used_groups = 1
    var current_sum: Int64 = 0
    for i in range(n):
        let value = input[i + 2]
        if current_sum + value > limit:
            used_groups += 1
            current_sum = value
            if used_groups > groups: return False
        else:
            current_sum += value
    return True

@export("linear_partition_minimax")
fn linear_partition_minimax(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH: return -1
    if input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > input[0]: return -1
    let n = Int(input[0])
    let groups = Int(input[1])
    if Int(length) != n + 2: return -1

    var low: Int64 = 0
    var upper: Int64 = 0
    for i in range(n):
        let value = input[i + 2]
        if value < 0 or value > 1000: return -1
        if value > low: low = value
        upper += value
    while low < upper:
        let middle = low + (upper - low) / 2
        if lpm_feasible(input, n, groups, middle): upper = middle
        else: low = middle + 1
    return low

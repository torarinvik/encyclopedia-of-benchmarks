from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer, stack_allocation


@export("random_permutation_cycle_cap_count")
fn random_permutation_cycle_cap_count(input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length != 2:
        return -1
    let n_value = input[0]
    let cap_value = input[1]
    if n_value < 1 or n_value > 20 or cap_value < 1 or cap_value > n_value:
        return -1

    let n = Int(n_value)
    let cap = Int(cap_value)
    var counts = stack_allocation[21, Int64]()
    for index in range(21):
        counts[index] = 0
    counts[0] = 1
    for size in range(1, n + 1):
        var total: Int64 = 0
        var cycle_choices: Int64 = 1
        var limit = size
        if cap < limit:
            limit = cap
        for cycle_length in range(1, limit + 1):
            if cycle_length > 1:
                cycle_choices *= Int64(size - cycle_length + 1)
            total += cycle_choices * counts[size - cycle_length]
        counts[size] = total
    return counts[n]

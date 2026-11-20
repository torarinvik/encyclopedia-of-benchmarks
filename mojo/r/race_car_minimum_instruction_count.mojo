from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("race_car_minimum_instruction_count")
fn race_car_minimum_instruction_count(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2:
        return -1
    if length != 1:
        return -1
    let target_value = input[0]
    if target_value < 0 or target_value > 127:
        return -1
    let target = Int(target_value)
    var distance = InlineArray[Int32, 128]()

    for position in range(1, target + 1):
        var run = 0
        var upper_power = 1
        while upper_power <= position:
            upper_power *= 2
            run += 1
        let upper = upper_power - 1
        if position == upper:
            distance[position] = Int32(run)
            continue

        var best = Int32(run + 1) + distance[upper - position]
        let lower = upper_power // 2 - 1
        var backward_run = 0
        var backward_power = 1
        while backward_run + 1 < run:
            let backward_distance = backward_power - 1
            let remaining = position - (lower - backward_distance)
            let candidate = Int32(run + backward_run + 1) + distance[remaining]
            if candidate < best:
                best = candidate
            backward_power *= 2
            backward_run += 1
        distance[position] = best
    return Int64(distance[target])

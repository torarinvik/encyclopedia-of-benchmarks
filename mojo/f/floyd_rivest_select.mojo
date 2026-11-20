from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import ceil, exp, floor, log, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_VALUES = 64
alias MAX_INPUT_LENGTH = 67
alias SAMPLE_THRESHOLD = 24

fn floyd_rivest_select_range(inout values: InlineArray[Int64, MAX_VALUES],
        left_input: Int, right_input: Int, target: Int):
    var left = left_input
    var right = right_input
    while True:
        if right - left > SAMPLE_THRESHOLD:
            let active_count = right - left + 1
            let relative_rank = target - left + 1
            let active_count_f = Float64(active_count)
            let relative_rank_f = Float64(relative_rank)
            let z = sqrt(log(active_count_f))
            let sample_size = 0.5 * exp(2.0 * z / 3.0)
            var direction: Float64 = 0.0
            if 2 * relative_rank < active_count:
                direction = -1.0
            elif 2 * relative_rank > active_count:
                direction = 1.0
            let spread = 0.5 * sqrt(z * sample_size *
                (active_count_f - sample_size) / active_count_f) * direction
            let lower_estimate = Float64(target) -
                relative_rank_f * sample_size / active_count_f + spread
            let upper_estimate = Float64(target) +
                (active_count_f - relative_rank_f) * sample_size / active_count_f + spread
            var sample_left = Int(floor(lower_estimate))
            if sample_left < left: sample_left = left
            if sample_left > target: sample_left = target
            var sample_right = Int(ceil(upper_estimate))
            if sample_right < target: sample_right = target
            if sample_right > right: sample_right = right
            floyd_rivest_select_range(inout values, sample_left, sample_right, target)

        let pivot = values[target]
        var less = left
        var scan = left
        var greater = right
        while scan <= greater:
            if values[scan] < pivot:
                let temporary = values[less]
                values[less] = values[scan]
                values[scan] = temporary
                less += 1
                scan += 1
            elif values[scan] > pivot:
                let temporary = values[greater]
                values[greater] = values[scan]
                values[scan] = temporary
                greater -= 1
            else:
                scan += 1
        if target < less:
            right = less - 1
        elif target > greater:
            left = greater + 1
        else:
            return

@export("floyd_rivest_select")
fn floyd_rivest_select(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
            length < 3 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_count = input[0]
    let raw_rank = input[1]
    if raw_count < 1 or raw_count > MAX_VALUES or raw_rank < 0 or raw_rank >= raw_count:
        return -1
    let count = Int(raw_count)
    if length != c_size_t(count + 2):
        return -1

    var values = InlineArray[Int64, MAX_VALUES](fill=0)
    for index in range(count):
        let value = input[index + 2]
        if value < 0 or value > 2147483647:
            return -1
        for previous in range(index):
            if values[previous] == value:
                return -1
        values[index] = value

    let target = Int(raw_rank)
    floyd_rivest_select_range(inout values, 0, count - 1, target)
    return values[target]

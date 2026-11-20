from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MAX_INPUT_LENGTH = 130

@export("segment_union_length_klee")
fn segment_union_length_klee(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N: return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 2 * n): return -1
    var events = InlineArray[Int64, 128](0)
    for i in range(n):
        let left = input[1 + 2 * i]
        let right = input[2 + 2 * i]
        if left < -1000 or left > right or right > 1000: return -1
        events[2 * i] = 2 * (left + 1000)
        events[2 * i + 1] = 2 * (right + 1000) + 1
    let event_count = 2 * n
    if event_count == 0: return 0

    var start = event_count / 2
    while start > 0:
        start -= 1
        var root = start
        while root < event_count / 2:
            var child = 2 * root + 1
            if child + 1 < event_count and events[child] < events[child + 1]: child += 1
            if events[root] >= events[child]: break
            let temporary = events[root]
            events[root] = events[child]
            events[child] = temporary
            root = child
    var end = event_count
    while end > 1:
        end -= 1
        let temporary = events[0]
        events[0] = events[end]
        events[end] = temporary
        var root = 0
        while root < end / 2:
            var child = 2 * root + 1
            if child + 1 < end and events[child] < events[child + 1]: child += 1
            if events[root] >= events[child]: break
            let swap_value = events[root]
            events[root] = events[child]
            events[child] = swap_value
            root = child

    var active: Int64 = 0
    var total: Int64 = 0
    var previous: Int64 = 0
    var index = 0
    while index < event_count:
        let coordinate_code = events[index] / 2
        let coordinate = coordinate_code - 1000
        if index > 0 and active > 0: total += coordinate - previous
        var delta: Int64 = 0
        while index < event_count and events[index] / 2 == coordinate_code:
            if events[index] % 2 == 0: delta += 1
            else: delta -= 1
            index += 1
        active += delta
        previous = coordinate
    return total

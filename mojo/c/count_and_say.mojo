from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("count_and_say")
fn count_and_say(term_index: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if term_index < 1 or term_index > 19: return -1
    var current = InlineArray[UInt8, 256](0)
    var next = InlineArray[UInt8, 256](0)
    var current_length: Int64 = 1
    current[0] = 49
    for term in range(1, term_index):
        var next_length: Int64 = 0
        var index: Int64 = 0
        while index < current_length:
            var end = index + 1
            while end < current_length and current[end] == current[index]: end += 1
            let run_length = end - index
            if next_length + 2 > 256: return -1
            next[next_length] = UInt8(48 + run_length)
            next[next_length + 1] = current[index]
            next_length += 2
            index = end
        for i in range(next_length): current[i] = next[i]
        current_length = next_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < current_length: return -2
    for i in range(current_length): output[i] = current[i]
    return current_length

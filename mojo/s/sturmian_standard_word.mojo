from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_STEPS = 4
alias MAX_WORD = 41

@export("sturmian_standard_word")
fn sturmian_standard_word(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 6: return -1
    let steps_word = input[0]
    if steps_word < 0 or steps_word > MAX_STEPS: return -1
    let steps = Int(steps_word)
    if length != c_size_t(steps + 1): return -1

    var directives = InlineArray[Int64, MAX_STEPS](fill=0)
    for i in range(steps):
        let repeat = input[i + 1]
        if i == 0:
            if repeat < 0 or repeat > 2: return -1
        else:
            if repeat < 1 or repeat > 2: return -1
        directives[i] = repeat

    var previous = InlineArray[UInt8, MAX_WORD](fill=0)
    var current = InlineArray[UInt8, MAX_WORD](fill=0)
    var following = InlineArray[UInt8, MAX_WORD](fill=0)
    previous[0] = UInt8(98)
    current[0] = UInt8(97)
    var previous_length = 1
    var current_length = 1
    for step in range(steps):
        let repeat = Int(directives[step])
        let following_length = current_length * repeat + previous_length
        var position = 0
        for _ in range(repeat):
            for i in range(current_length):
                following[position] = current[i]
                position += 1
        for i in range(previous_length):
            following[position] = previous[i]
            position += 1
        for i in range(current_length): previous[i] = current[i]
        for i in range(following_length): current[i] = following[i]
        previous_length = current_length
        current_length = following_length

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(current_length): return -2
    for i in range(current_length): output[i] = current[i]
    return Int64(current_length)

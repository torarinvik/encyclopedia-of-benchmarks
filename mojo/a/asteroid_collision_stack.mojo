from memory import UnsafePointer
from sys.ffi import c_size_t

comptime MAX_N = 64
comptime MAX_INPUT = 66

@export("asteroid_collision_stack")
fn asteroid_collision_stack(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT:
        return -1
    let n_word = input[0]
    if n_word < 0 or n_word > MAX_N or length != c_size_t(n_word + 1):
        return -1

    var stack = InlineArray[Int64, MAX_N](fill=0)
    var top = 0
    for i in range(n_word):
        let word = input[i + 1]
        if word == 0 or word < -127 or word > 127:
            return -1
        let incoming = word
        var alive = True
        while alive and top > 0 and stack[top - 1] > 0 and incoming < 0:
            let left_size = Int64(stack[top - 1])
            let right_size = -incoming
            if left_size < right_size:
                top -= 1
            elif left_size == right_size:
                top -= 1
                alive = False
            else:
                alive = False
        if alive:
            stack[top] = incoming
            top += 1

    let required = top + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    output[0] = UInt8(top)
    for i in range(top):
        output[i + 1] = UInt8(UInt64(stack[i]) & 255)
    return Int64(required)

package asteroid_collision_stack

import "core:c"

MAX_N :: 64
MAX_INPUT :: 66

@(export)
asteroid_collision_stack :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT) do return -1
    n_word := input[0]
    if n_word < 0 || n_word > MAX_N || length != c.size_t(n_word + 1) do return -1

    stack: [MAX_N]i8
    top := 0
    for i := 0; i < int(n_word); i += 1 {
        word := input[i + 1]
        if word == 0 || word < -127 || word > 127 do return -1
        incoming := i8(word)
        alive := true
        for alive && top > 0 && stack[top - 1] > 0 && incoming < 0 {
            left_size := int(stack[top - 1])
            right_size := -int(incoming)
            if left_size < right_size do top -= 1
            else if left_size == right_size {
                top -= 1
                alive = false
            } else alive = false
        }
        if alive {
            stack[top] = incoming
            top += 1
        }
    }

    required := top + 1
    if output == nil || capacity < c.size_t(required) do return -2
    output[0] = u8(top)
    for i := 0; i < top; i += 1 {
        output[i + 1] = u8(i16(stack[i]) & 255)
    }
    return i64(required)
}

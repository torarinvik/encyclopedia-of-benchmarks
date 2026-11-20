package domino_l_tromino_tilings_2xn

import "core:c"

MAX_WIDTH :: i64(32)
MAX_PARSEABLE_LENGTH :: 2

count_tilings :: proc(width: i64) -> i64 {
    state0 := i64(1)
    state1 := i64(0)
    state2 := i64(0)
    state3 := i64(0)
    for _ in 0..<int(width) {
        next0 := state0 + state3
        next1 := state0 + state2
        next2 := state0 + state1
        next3 := state0 + state1 + state2
        state0 = next0
        state1 = next1
        state2 = next2
        state3 = next3
    }
    return state0
}

@(export)
domino_l_tromino_tilings_2xn :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if length != 1 || input[0] < 0 || input[0] > MAX_WIDTH do return -1
    return count_tilings(input[0])
}

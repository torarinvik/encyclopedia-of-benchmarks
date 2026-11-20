package pisano_period

import "core:c"

MAX_MODULUS :: i64(64)
MAX_INPUT_LENGTH :: 2

@(export)
pisano_period :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_MODULUS do return -1
    modulus := input[0]
    initial_next := i64(1) % modulus
    previous := i64(0)
    current := initial_next
    for period := i64(1); period <= 6 * modulus; period += 1 {
        next := (previous + current) % modulus
        previous = current
        current = next
        if previous == 0 && current == initial_next do return period
    }
    return -1
}

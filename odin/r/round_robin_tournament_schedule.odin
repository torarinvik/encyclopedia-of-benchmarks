package round_robin_tournament_schedule

import "core:c"

MAX_TEAMS :: 8
MAX_PARSEABLE_INPUT :: 2
MAX_CELLS :: 64

@(export)
round_robin_tournament_schedule :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
    if length != 1 do return -1
    n_word := input[0]
    if n_word < 2 || n_word > MAX_TEAMS do return -1

    n := int(n_word)
    padded := n + (n & 1)
    ring_size := padded - 1
    rounds := ring_size
    fixed := padded - 1
    table: [MAX_CELLS]u8
    for i := 0; i < MAX_CELLS; i += 1 { table[i] = 255 }

    for round := 0; round < rounds; round += 1 {
        if fixed < n {
            table[fixed * rounds + round] = u8(round)
            table[round * rounds + round] = u8(fixed)
        }
        for offset := 1; offset < padded / 2; offset += 1 {
            left := (round + offset) % ring_size
            right := (round + ring_size - offset) % ring_size
            if left < n && right < n {
                table[left * rounds + round] = u8(right)
                table[right * rounds + round] = u8(left)
            }
        }
    }

    required := 2 + n * rounds
    if output == nil || capacity < c.size_t(required) do return -2
    output[0] = u8(n)
    output[1] = u8(rounds)
    for i := 0; i < n * rounds; i += 1 { output[i + 2] = table[i] }
    return i64(required)
}

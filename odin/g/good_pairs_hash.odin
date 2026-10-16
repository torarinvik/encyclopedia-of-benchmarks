package good_pairs_hash

import "core:c"

MAX_ARRAY_LENGTH :: 256
MAX_INPUT_LENGTH :: 258
TABLE_SIZE :: 512

@(export)
good_pairs_hash :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < c.size_t(1) || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    declared := input[0]
    if declared < 0 || declared > MAX_ARRAY_LENGTH || length != c.size_t(declared + 1) do return -1
    n := int(declared)
    keys: [TABLE_SIZE]i64
    frequencies: [TABLE_SIZE]u64
    occupied: [TABLE_SIZE]bool
    for index in 0..<n {
        value := input[index + 1]
        if value < -1_000_000 || value > 1_000_000 do return -1
        slot := int(((value + 1_000_000) * 2_654_435_761) % TABLE_SIZE)
        for occupied[slot] && keys[slot] != value { slot = (slot + 1) % TABLE_SIZE }
        if !occupied[slot] { occupied[slot] = true; keys[slot] = value }
        frequencies[slot] += 1
    }
    pairs: u64 = 0
    for frequency in frequencies {
        if frequency > 1 do pairs += frequency * (frequency - 1) / 2
    }
    return i64(pairs)
}

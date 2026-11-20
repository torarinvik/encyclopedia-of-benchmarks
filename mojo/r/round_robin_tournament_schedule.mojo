from memory import UnsafePointer
from std.collections import InlineArray
from sys.ffi import c_size_t

comptime MAX_TEAMS = 8
comptime MAX_PARSEABLE_INPUT = 2
comptime MAX_CELLS = 64

@export("round_robin_tournament_schedule")
fn round_robin_tournament_schedule(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    if length != 1:
        return -1
    let n_word = input[0]
    if n_word < 2 or n_word > MAX_TEAMS:
        return -1

    let n = Int(n_word)
    let padded = n + (n & 1)
    let ring_size = padded - 1
    let rounds = ring_size
    let fixed = padded - 1
    var table = InlineArray[UInt8, MAX_CELLS](fill=UInt8(255))
    for round in range(rounds):
        if fixed < n:
            table[fixed * rounds + round] = UInt8(round)
            table[round * rounds + round] = UInt8(fixed)
        for offset in range(1, padded // 2):
            let left = (round + offset) % ring_size
            let right = (round + ring_size - offset) % ring_size
            if left < n and right < n:
                table[left * rounds + round] = UInt8(right)
                table[right * rounds + round] = UInt8(left)

    let required = 2 + n * rounds
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    output[0] = UInt8(n)
    output[1] = UInt8(rounds)
    for i in range(n * rounds):
        output[i + 2] = table[i]
    return Int64(required)

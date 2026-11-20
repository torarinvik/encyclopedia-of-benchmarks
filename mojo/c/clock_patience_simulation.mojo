from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("clock_patience_simulation")
fn clock_patience_simulation(values: UnsafePointer[Int64, ImmutAnyOrigin],
                             length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 52:
        return -1

    var rank_counts = InlineArray[Int64, 14]()
    for index in range(52):
        let rank = values[index]
        if rank < 1 or rank > 13:
            return -1
        rank_counts[Int(rank)] += 1
    for rank in range(1, 14):
        if rank_counts[rank] != 4:
            return -1

    var next_card = InlineArray[Int, 13]()
    var pile = 12
    var revealed = 0
    while next_card[pile] < 4:
        let rank = values[pile * 4 + next_card[pile]]
        next_card[pile] += 1
        revealed += 1
        pile = Int(rank - 1)
    return 1 if revealed == 52 else 0

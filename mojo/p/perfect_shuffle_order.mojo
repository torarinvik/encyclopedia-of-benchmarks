from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_DECK_SIZE = 10000

@export("perfect_shuffle_order")
fn perfect_shuffle_order(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let deck_size_word = input[0]
    if deck_size_word < 2 or deck_size_word > MAX_DECK_SIZE or deck_size_word % 2 != 0:
        return -1
    let deck_size = Int(deck_size_word)
    let half = deck_size // 2

    var deck = InlineArray[Int64, MAX_DECK_SIZE]()
    var following = InlineArray[Int64, MAX_DECK_SIZE]()
    for index in range(deck_size):
        deck[index] = Int64(index)

    var repetitions: Int64 = 0
    while True:
        for index in range(half):
            following[index * 2] = deck[index]
            following[index * 2 + 1] = deck[half + index]
        repetitions += 1

        var restored = True
        for index in range(deck_size):
            if following[index] != Int64(index):
                restored = False
                break
        if restored:
            return repetitions

        for index in range(deck_size):
            deck[index] = following[index]

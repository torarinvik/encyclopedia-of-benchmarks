from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_exceeding")
fn check_exceeding(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -2
    var previous_letter: Int64 = -1
    var previous_gap: Int64 = -1
    for i in range(length):
        var letter = values[i]
        if letter >= 97 and letter <= 122: letter -= 32
        if letter < 65 or letter > 90: continue
        if previous_letter >= 0 and letter != previous_letter:
            let difference = letter - previous_letter
            let gap = difference if difference > 0 else -difference
            if previous_gap >= 0 and gap < previous_gap: return 0
            previous_gap = gap
        previous_letter = letter
    return 1

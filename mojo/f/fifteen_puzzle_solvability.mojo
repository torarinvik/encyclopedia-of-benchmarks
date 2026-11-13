from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fifteen_puzzle_solvability(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 16:
        return -1

    var blank: Int = -1
    for i in range(16):
        let value = input[i]
        if value < 0 or value >= 16:
            return -1
        for j in range(i):
            if value == input[j]:
                return -1
        if value == 0:
            blank = i
    if blank < 0:
        return -1

    var inversions: Int = 0
    for i in range(16):
        if input[i] == 0:
            continue
        for j in range(i + 1, 16):
            if input[j] != 0 and input[i] > input[j]:
                inversions += 1
    let blank_row_from_top = blank // 4 + 1
    if (inversions + blank_row_from_top) % 2 == 0:
        return Int64(1)
    return Int64(0)

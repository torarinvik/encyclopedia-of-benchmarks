from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("bingo_sort")
fn bingo_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length < 2 or length > 1024 or values == UnsafePointer[Int64, MutAnyOrigin](): return
    let n = Int(length)
    var bingo = values[0]
    for i in range(1, n): bingo = min(bingo, values[i])
    var next_position = 0
    while next_position < n:
        var has_next = False; var next_bingo: Int64 = 0
        var i = next_position
        while i < n:
            if values[i] == bingo:
                let temp = values[i]; values[i] = values[next_position]; values[next_position] = temp
                next_position += 1
            elif not has_next or values[i] < next_bingo:
                next_bingo = values[i]; has_next = True
            i += 1
        if next_position == n: break
        bingo = next_bingo

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("egg_drop_max_floors_by_moves")
fn egg_drop_max_floors_by_moves(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let eggs = input[0]
    let moves = input[1]
    if eggs < 0 or eggs > 32 or moves < 0 or moves > 32: return -1
    var covered = InlineArray[Int64, 33](fill=0)
    for move in range(Int(moves)):
        var egg = Int(eggs)
        while egg > 0:
            covered[egg] += covered[egg - 1] + 1
            egg -= 1
    return covered[Int(eggs)]

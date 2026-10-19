from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("board_path")
fn board_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let start = input[0]; let finish = input[1]
    if start < 0 or finish < start or finish > 30: return -1
    var ways = List[Int64](capacity=31); for _ in range(31): ways.append(0)
    ways[Int(finish)] = 1
    var pos = Int(finish) - 1
    while pos >= Int(start):
        var total: Int64 = 0
        for step in range(1, 7):
            if pos + step <= Int(finish): total += ways[pos + step]
        ways[pos] = total; pos -= 1
    return ways[Int(start)]

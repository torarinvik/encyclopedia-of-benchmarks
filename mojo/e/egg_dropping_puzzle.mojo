from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("egg_dropping_puzzle")
fn egg_dropping_puzzle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let eggs = input[0]; let floors = input[1]
    if eggs < 1 or eggs > 8 or floors < 1 or floors > 32: return -1
    var table = List[Int64](length=9, fill=0)
    var rounds: Int64 = 0
    while table[Int(eggs)] < floors:
        rounds += 1
        for e in range(Int(eggs), 0, -1): table[e] = table[e] + table[e - 1] + 1
    return rounds

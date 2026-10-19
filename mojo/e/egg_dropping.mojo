from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("egg_dropping")
fn egg_dropping(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -9223372036854775808
    let eggs = input[0]; let floors = input[1]
    if eggs < 1 or eggs > 12 or floors < 1 or floors > 128: return -9223372036854775808
    var reach = List[Int64](length=13, fill=0)
    var drops: Int64 = 0
    while reach[Int(eggs)] < floors:
        drops += 1
        for e in range(Int(eggs), 0, -1): reach[e] = reach[e] + reach[e - 1] + 1
    return drops

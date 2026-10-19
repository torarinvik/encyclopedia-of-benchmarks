from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("average_mode")
fn average_mode(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 64: return -1
    var counts = List[Int](length=1001, fill=0)
    for i in range(Int(length)):
        if values[i] < 0 or values[i] > 1000: return -1
        counts[Int(values[i])] += 1
    var best = 0
    var mode: Int64 = -1
    var tied = False
    for value in range(1001):
        if counts[value] > best:
            best = counts[value]
            mode = Int64(value)
            tied = False
        elif counts[value] == best and best > 0:
            tied = True
    if tied: return -1
    return mode

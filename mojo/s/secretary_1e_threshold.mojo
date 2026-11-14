from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("secretary_1e_threshold")
fn secretary_1e_threshold(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 17: return -1
    let n0 = input[0]
    if n0 < 3 or n0 > 16 or length != c_size_t(n0 + 1): return -1
    let n = Int(n0)
    var seen = List[Bool](length=n + 1, fill=False)
    for i in range(n):
        let rank = input[i + 1]
        if rank < 1 or rank > n0: return -1
        if seen[Int(rank)]: return -1
        seen[Int(rank)] = True
    var observed = 0
    for index in range(1, n + 1):
        if index == 3 or index == 6 or index == 9 or index == 11 or index == 14:
            observed += 1
    var threshold = input[1]
    for i in range(1, observed):
        if input[i + 1] > threshold: threshold = input[i + 1]
    var selected = Int64(-1)
    for i in range(observed, n):
        if input[i + 1] > threshold:
            selected = Int64(i)
            break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((selected >> (8 * byte)) & 255)
    return 8

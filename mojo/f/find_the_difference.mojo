from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_the_difference")
fn find_the_difference(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 8195: return -1
    let ns = input[0]
    let nt = input[1]
    if ns < 0 or ns > 4096 or nt < 1 or nt > 4097 or nt != ns + 1 or length != 2 + ns + nt: return -1
    var sum_s: Int64 = 0
    var sum_t: Int64 = 0
    for i in range(ns):
        let c = input[2 + i]
        if c < 97 or c > 122: return -1
        sum_s += c
    let start = 2 + ns
    for i in range(nt):
        let c = input[start + i]
        if c < 97 or c > 122: return -1
        sum_t += c
    let difference = sum_t - sum_s
    return difference if difference >= 97 and difference <= 122 else -1

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn decimal_exp(base: Int64) -> Int64:
    if base < 1: return -1
    var b = base; var e: Int64 = 0
    while b > 1 and b % 10 == 0: b /= 10; e += 1
    if b == 1: return e
    return -1

@export("largest_of_very_large_numbers")
fn largest_of_very_large_numbers(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 4: return -2
    for i in range(4):
        if v[i] < 0 or v[i] > 1000000000000: return -2
    let ea = decimal_exp(v[0]); let eb = decimal_exp(v[2])
    if (v[0] != 0 and ea < 0) or (v[2] != 0 and eb < 0): return -2
    let a = if v[0] == 0: 0 elif v[1] == 0: 1 else: ea * v[1]
    let b = if v[2] == 0: 0 elif v[3] == 0: 1 else: eb * v[3]
    return (a > b).cast[Int64]() - (a < b).cast[Int64]()

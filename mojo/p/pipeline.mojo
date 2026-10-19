from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("pipeline")
fn pipeline(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 66: return -1
    let initial = v[0]; let count = v[1]
    if initial < 0 or initial > 2 or count < 1 or count > 32 or n != c_size_t(2 + 2 * count): return -1
    var result = initial
    for i in range(Int(count)):
        let op = v[2 + 2 * i]; let arg = v[3 + 2 * i]
        if arg < 0 or arg > 2: return -1
        if op == 0: result += arg
        elif op == 1: result *= arg
        else: return -1
    return result

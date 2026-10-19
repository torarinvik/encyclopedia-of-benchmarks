from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_substrings")
fn count_substrings(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 8194: return -1
    let nt = values[0]
    let np = values[1]
    if nt < 0 or nt > 4096 or np < 0 or np > 4096 or length != 2 + nt + np: return -1
    for i in range(2, length):
        if values[i] < 0 or values[i] > 127: return -1
    if np == 0: return nt + 1
    if np > nt: return 0
    var result: Int64 = 0
    for start in range(nt - np + 1):
        var matched = True
        for offset in range(np):
            if values[2 + start + offset] != values[2 + nt + offset]: matched = False
        if matched: result += 1
    return result

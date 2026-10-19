from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("plus_one")
fn plus_one(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if n > 256 or (n != 0 and v == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var all_nines = True
    for i in range(Int(n)):
        if v[i] < 0 or v[i] > 9: return -1
        if v[i] != 9: all_nines = False
    if n > 1 and v[0] == 0: return -1
    let out_len = Int(n) + (1 if n == 0 or all_nines else 0)
    if cap < c_size_t(out_len): return -2
    if out == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    if n == 0 or all_nines:
        out[0] = 49
        for i in range(1, out_len): out[i] = 48
        return Int64(out_len)
    for i in range(Int(n)): out[i] = UInt8(48 + v[i])
    for i in range(Int(n)):
        let idx = Int(n) - 1 - i
        if v[idx] == 9: out[idx] = 48
        else: out[idx] += 1; break
    return Int64(out_len)

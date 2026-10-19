from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pig_latin")
fn pig_latin(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != c_size_t(v[0] + 1): return -1
    let count = Int(v[0])
    if count == 0: return 0
    if cap < c_size_t(count + 3) or out == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var pivot = count
    for i in range(count):
        var ch = v[i + 1]
        if ch >= 65 and ch <= 90: ch += 32
        if ch < 97 or ch > 122: return -1
        out[i] = UInt8(ch)
        if pivot == count and (ch == 97 or ch == 101 or ch == 105 or ch == 111 or ch == 117): pivot = i
    if pivot == count: return -1
    if pivot == 0:
        out[count] = 119; out[count + 1] = 97; out[count + 2] = 121
        return Int64(count + 3)
    for i in range(pivot): out[count + i] = out[i]
    for i in range(count - pivot): out[i] = out[pivot + i]
    out[count] = 97; out[count + 1] = 121
    return Int64(count + 2)

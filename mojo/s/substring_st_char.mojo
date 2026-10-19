from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("substring_st_char")
fn substring_st_char(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 130: return -1
    let target = v[0]
    let requested = v[1]
    if target < 1 or target > 127 or requested < 0 or requested > 64: return -1
    let text_n = Int(n) - 2
    for i in range(text_n):
        if v[2+i] < 1 or v[2+i] > 127: return -1
    var start = -1
    for i in range(text_n):
        if start < 0 and v[2+i] == target: start = i
    if start < 0: return -1
    let remaining = text_n - start
    var count = Int(requested)
    if count == 0: count = 1
    if count > remaining: count = remaining
    var checksum: Int64 = 0
    for i in range(count): checksum += Int64(i+1) * v[2+start+i]
    return Int64(count) * 300000 + checksum

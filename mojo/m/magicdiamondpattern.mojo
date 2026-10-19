from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("magicdiamondpattern")
fn magicdiamondpattern(n: Int64, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if n > 45: return -1
    var staged = InlineArray[UInt8, 6255](fill=0)
    var p = 0
    if n <= 0:
        let sentinel = InlineArray[UInt8, 48](32,32,32,32,32,32,32,46,46,46,32,32,32,32,32,32,32,46,46,46,46,32,32,32,32,32,32,32,32,110,111,116,104,105,110,103,32,112,114,105,110,116,105,110,103,32,58,40)
        for i in range(48): staged[i] = sentinel[i]
        p = 48
    else:
        let side = Int(n)
        for i in range(side):
            for j in range(side-i-1): staged[p] = 32; p += 1
            for j in range(i+1): staged[p] = 42; p += 1; staged[p] = 32; p += 1
            staged[p] = 10; p += 1
        for rev in range(side):
            let i = side - rev
            for j in range(i): staged[p] = 42; p += 1; staged[p] = 32; p += 1
            staged[p] = 10; p += 1
            for j in range(side-i+1): staged[p] = 32; p += 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(p): return -2
    for i in range(p): out[i] = staged[i]
    return Int64(p)

# Uncompiled monotone-cursor Prüfer decoder draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn pdl_write(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int):
    var bits = UInt64(value)
    for i in range(8):
        output[offset+i] = UInt8(bits & 255)
        bits >>= 8

@export("prufer_decode_linear")
fn prufer_decode_linear(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4096: return -1
    let nv = input[0]
    if nv < 2 or nv > 4096 or length != c_size_t(nv-1): return -1
    let n = Int(nv)
    var count = InlineArray[Int,4096](fill=0)
    for i in range(1,Int(length)):
        if input[i] < 0 or input[i] >= nv: return -1
        count[Int(input[i])] += 1
    let needed = 16*(n-1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var cursor = n-1
    while count[cursor] != 0: cursor -= 1
    var leaf = cursor
    for i in range(1,Int(length)):
        let v = Int(input[i])
        pdl_write(output, 16*(i-1), leaf)
        pdl_write(output, 16*(i-1)+8, v)
        count[leaf] = -1
        count[v] -= 1
        if count[v] == 0 and v > cursor: leaf = v
        else:
            cursor -= 1
            while count[cursor] != 0: cursor -= 1
            leaf = cursor
    var other = 0
    while other == leaf or count[other] != 0: other += 1
    pdl_write(output, 16*(n-2), leaf)
    pdl_write(output, 16*(n-2)+8, other)
    return Int64(needed)

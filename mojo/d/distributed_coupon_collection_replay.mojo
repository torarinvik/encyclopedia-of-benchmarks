# Independent deterministic coupon-collection replay; see package provenance.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("distributed_coupon_collection_replay")
fn distributed_coupon_collection_replay(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 76: return -1
    let nv = input[0]
    let cv = input[1]
    let copies = input[2]
    let tv = input[3]
    if nv < 2 or nv > 8 or cv < 1 or cv > 8 or copies < 1 or copies > nv or tv < 1 or tv > 8: return -1
    let n = Int(nv)
    let coupons = Int(cv)
    let steps = Int(tv)
    if length != c_size_t(4+n+n*steps): return -1
    let limit = Int64(1) << coupons
    for bin in range(n):
        if input[4+bin] < 0 or input[4+bin] >= limit: return -1
    for coupon in range(coupons):
        var count = Int64(0)
        for bin in range(n):
            if ((input[4+bin] >> coupon) & 1) != 0: count += 1
        if count < copies: return -1
    let tape = 4+n
    for i in range(n*steps):
        if input[tape+i] != 0 and input[tape+i] != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var collected = Int64(0)
    var singleton_steps = Int64(0)
    for t in range(steps):
        var open_count = 0
        var selected = 0
        for bin in range(n):
            if input[tape+t*n+bin] == 1:
                open_count += 1
                selected = bin
        if open_count == 1:
            singleton_steps += 1
            collected |= input[4+selected]
    for byte in range(8):
        output[byte] = UInt8((collected >> (8*byte)) & 255)
        output[8+byte] = UInt8((singleton_steps >> (8*byte)) & 255)
    return 16

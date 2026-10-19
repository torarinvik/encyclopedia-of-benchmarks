from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn nested_feed(h0: UInt64, value: Int64) -> UInt64:
    var h = h0
    let bits = UInt64(value)
    for b in range(8):
        h ^= UInt64(UInt8((bits >> (8 * b)) & 255))
        h *= 0x100000001b3
    return h

fn nested_signed_hash(hash:UInt64)->Int64:
    let sign:UInt64=0x8000000000000000
    if hash<sign:return Int64(hash)
    let magnitude=UInt64(0xffffffffffffffff)-hash+1
    if magnitude==sign:return -9223372036854775807-1
    return -Int64(magnitude)

@export("flatten_nested_list")
fn flatten_nested_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 255 or input[0] != -9223372036854775808: return -1
    var depth = 0
    var closed = False
    var h: UInt64 = 0xcbf29ce484222325
    for i in range(Int(length)):
        let x = input[i]
        if x == -9223372036854775808:
            if closed or (depth == 0 and i != 0): return -1
            depth += 1
            if depth > 16: return -1
        elif x == -9223372036854775807:
            if depth == 0: return -1
            depth -= 1
            if depth == 0:
                closed = True
                if i != Int(length) - 1: return -1
        else:
            if depth == 0 or x < -1000000 or x > 1000000: return -1
            h = nested_feed(h, x)
    if depth != 0 or not closed: return -1
    return nested_signed_hash(h)

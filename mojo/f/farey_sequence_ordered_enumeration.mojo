from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn farey_count(order: Int64) -> Int64:
    var a: Int64 = 0
    var b: Int64 = 1
    var c: Int64 = 1
    var d = order
    var count: Int64 = 1
    while True:
        count += 1
        if c == d: break
        let k = (order + b) // d
        let next_c = k * c - a
        let next_d = k * d - b
        a = c
        b = d
        c = next_c
        d = next_d
    return count

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("farey_sequence_ordered_enumeration")
fn farey_sequence_ordered_enumeration(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let order = input[0]
    if order < 1 or order > 32: return -1
    let count = farey_count(order)
    let required = Int((1 + 2 * count) * 8)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    store_i64_le(output, 0, count)
    store_i64_le(output, 8, 0)
    store_i64_le(output, 16, 1)
    var a: Int64 = 0
    var b: Int64 = 1
    var c: Int64 = 1
    var d = order
    var position = 24
    while True:
        store_i64_le(output, position, c)
        store_i64_le(output, position + 8, d)
        position += 16
        if c == d: break
        let k = (order + b) // d
        let next_c = k * c - a
        let next_d = k * d - b
        a = c
        b = d
        c = next_c
        d = next_d
    return Int64(required)

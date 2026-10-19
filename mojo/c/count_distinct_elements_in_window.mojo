from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn distinct_hash_slot(value: Int64) -> Int64:
    let mixed = UInt64(UInt32(value)) * 2654435761
    return Int64(UInt32(mixed) >> 23)

fn distinct_find_slot(keys: InlineArray[Int64, 512], occupied: InlineArray[UInt8, 512], value: Int64) -> Int64:
    var slot = distinct_hash_slot(value)
    for probe in range(512):
        if occupied[slot] == 0 or keys[slot] == value: return slot
        slot = (slot + 1) % 512
    return 0

@export("count_distinct_elements_in_window")
fn count_distinct_elements_in_window(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or input[0] < 1 or input[0] > 256: return -1
    let n = input[0]
    let k = input[1]
    if k < 1 or k > n or length != n + 2: return -1
    for i in range(n):
        if input[i + 2] < -2147483648 or input[i + 2] > 2147483647: return -1
    let out_n = n - k + 1
    let bytes = out_n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var keys = InlineArray[Int64, 512](0)
    var counts = InlineArray[Int64, 512](0)
    var occupied = InlineArray[UInt8, 512](0)
    var distinct: Int64 = 0
    for i in range(k):
        let value = input[i + 2]
        let slot = distinct_find_slot(keys, occupied, value)
        if occupied[slot] == 0:
            keys[slot] = value
            occupied[slot] = 1
            counts[slot] = 0
        if counts[slot] == 0: distinct += 1
        counts[slot] += 1
    let first_bits = UInt64(distinct)
    for b in range(8): output[b] = UInt8((first_bits >> (8 * b)) & 255)
    for i in range(k, n):
        let incoming = input[i + 2]
        var slot = distinct_find_slot(keys, occupied, incoming)
        if occupied[slot] == 0:
            keys[slot] = incoming
            occupied[slot] = 1
            counts[slot] = 0
        if counts[slot] == 0: distinct += 1
        counts[slot] += 1
        let outgoing = input[i - k + 2]
        slot = distinct_find_slot(keys, occupied, outgoing)
        counts[slot] -= 1
        if counts[slot] == 0: distinct -= 1
        let bits = UInt64(distinct)
        let output_index = (i - k + 1) * 8
        for b in range(8): output[output_index + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes

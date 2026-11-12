from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn hj_bucket(key: Int64) -> Int:
    var remainder = key % 17
    if remainder < 0: remainder += 17
    return Int(remainder)

@export("hash_join")
fn hash_join(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 19: return -1
    let left_value = input[0]
    let right_value = input[1]
    if left_value < 0 or left_value > 8 or right_value < 0 or right_value > 8: return -1
    let left_count = Int(left_value)
    let right_count = Int(right_value)
    if length != c_size_t(2 + left_count + right_count): return -1

    let build_left = left_count < right_count
    let build_count = if build_left { left_count } else { right_count }
    let probe_count = if build_left { right_count } else { left_count }
    let build_offset = if build_left { 2 } else { 2 + left_count }
    let probe_offset = if build_left { 2 + left_count } else { 2 }
    var keys = InlineArray[Int64, 17](fill=0)
    var occupied = InlineArray[Bool, 17](fill=False)
    var heads = InlineArray[Int, 17](fill=-1)
    var tails = InlineArray[Int, 17](fill=-1)
    var next_row = InlineArray[Int, 8](fill=-1)
    var staged = InlineArray[UInt8, 64](fill=0)

    for row in range(build_count):
        let key = input[build_offset + row]
        var slot = hj_bucket(key)
        while occupied[slot] and keys[slot] != key: slot = (slot + 1) % 17
        if not occupied[slot]:
            occupied[slot] = True
            keys[slot] = key
        if tails[slot] < 0: heads[slot] = row
        else: next_row[tails[slot]] = row
        tails[slot] = row

    var match_count = 0
    for probe_row in range(probe_count):
        let key = input[probe_offset + probe_row]
        var slot = hj_bucket(key)
        while occupied[slot] and keys[slot] != key: slot = (slot + 1) % 17
        if not occupied[slot]: continue
        var build_row = heads[slot]
        while build_row >= 0:
            let left_id = if build_left { build_row } else { probe_row }
            let right_id = if build_left { probe_row } else { build_row }
            staged[match_count] = UInt8((left_id << 4) | right_id)
            match_count += 1
            build_row = next_row[build_row]
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(match_count): return -2
    for index in range(match_count): output[index] = staged[index]
    return Int64(match_count)

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("zobrist_position_hash_trace")
fn zobrist_position_hash_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    let slots = 16
    let features = 3
    let max_operations = 64
    let base_words = 1 + slots * features + slots
    let max_valid_words = base_words + 2 * max_operations
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(base_words) or length > c_size_t(max_valid_words + 1): return -1
    let count_value = input[0]
    if count_value < 0 or count_value > 64: return -1
    let count = Int(count_value)
    if length != c_size_t(base_words + 2 * count): return -1

    for index in range(slots * features):
        if input[1 + index] < 0: return -1
    let state_start = 1 + slots * features
    for slot in range(slots):
        let feature = input[state_start + slot]
        if feature < 0 or feature > features: return -1
    let edits_start = state_start + slots
    for edit in range(count):
        let slot = input[edits_start + 2 * edit]
        let feature = input[edits_start + 2 * edit + 1]
        if slot < 0 or slot >= slots or feature < 0 or feature > features: return -1

    let required = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var board = InlineArray[UInt8, 16](fill=0)
    var hash: Int64 = 0
    for slot in range(slots):
        let feature = UInt8(input[state_start + slot])
        board[slot] = feature
        if feature != 0:
            hash = hash ^ input[1 + slot * features + Int(feature) - 1]
    for byte in range(8):
        output[byte] = UInt8((hash >> (8 * byte)) & 255)

    for edit in range(count):
        let slot = Int(input[edits_start + 2 * edit])
        let next = UInt8(input[edits_start + 2 * edit + 1])
        let previous = board[slot]
        if previous != 0:
            hash = hash ^ input[1 + slot * features + Int(previous) - 1]
        if next != 0:
            hash = hash ^ input[1 + slot * features + Int(next) - 1]
        board[slot] = next
        for byte in range(8):
            output[8 * (edit + 1) + byte] = UInt8((hash >> (8 * byte)) & 255)
    return Int64(required)

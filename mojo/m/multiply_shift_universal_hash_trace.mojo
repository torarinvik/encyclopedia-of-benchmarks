from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("multiply_shift_universal_hash_trace")
fn multiply_shift_universal_hash_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    let max_queries = 32
    let word_mask: UInt64 = 0xFFFF_FFFF
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(67):
        return -1
    let width = input[0]
    let query_count = input[1]
    if width < 1 or width > 16 or query_count < 0 or query_count > max_queries:
        return -1
    let count = Int(query_count)
    if length != c_size_t(2 + 2 * count):
        return -1

    for query in range(count):
        let multiplier = input[2 + 2 * query]
        let key = input[3 + 2 * query]
        if multiplier < 1 or multiplier > 4294967295 or (multiplier & 1) == 0:
            return -1
        if key < 0 or key > 4294967295:
            return -1

    let required = count * 8
    if (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(required):
        return -2
    let shift = 32 - Int(width)
    for query in range(count):
        let multiplier = UInt64(input[2 + 2 * query])
        let key = UInt64(input[3 + 2 * query])
        let low_word = (multiplier * key) & word_mask
        let hash_value = low_word >> shift
        for byte in range(8):
            output.add(query * 8 + byte).write(UInt8((hash_value >> (8 * byte)) & 255))
    return Int64(required)

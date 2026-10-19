from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("common_characters_frequency_quotient")
fn common_characters_frequency_quotient(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1041: return -1
    let string_count = input[0]
    if string_count < 0 or string_count > 16: return -1
    var counts = InlineArray[Int64, 26](0)
    var offset: Int64 = 1
    var total: Int64 = 0
    for si in range(string_count):
        if offset >= length: return -1
        let n = input[offset]
        offset += 1
        if n < 0 or n > 64 or n > length - offset: return -1
        for i in range(n):
            let value = input[offset]
            offset += 1
            if value < 97 or value > 122: return -1
            counts[value - 97] += 1
        total += n
        if total > 512: return -1
    if offset != length: return -1
    var used: Int64 = 0
    if string_count > 0:
        for i in range(26): used += counts[i] / string_count
    if used > capacity or (used > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var pos: Int64 = 0
    if string_count > 0:
        for letter in range(26):
            for copy in range(counts[letter] / string_count):
                output[pos] = UInt8(97 + letter)
                pos += 1
    return used

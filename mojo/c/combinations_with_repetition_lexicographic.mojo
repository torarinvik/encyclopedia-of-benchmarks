from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_WORDS = 3

fn multiset_count(n: Int, r: Int) -> Int:
    if r == 0: return 1
    if n == 0: return 0
    let top = n + r - 1
    var result = 1
    for index in range(1, r + 1):
        result = result * (top - r + index) // index
    return result

@export("combinations_with_repetition_lexicographic")
fn combinations_with_repetition_lexicographic(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let n_word = input[0]
    let r_word = input[1]
    if n_word < 0 or n_word > 4 or r_word < 0 or r_word > 4: return -1
    let n = Int(n_word)
    let r = Int(r_word)
    let count = multiset_count(n, r)
    let byte_count = 2 + count * r
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2

    output[0] = UInt8(count & 255)
    output[1] = UInt8((count >> 8) & 255)
    var current = InlineArray[UInt8, 4](0, 0, 0, 0)
    for ordinal in range(count):
        for position in range(r):
            output[2 + ordinal * r + position] = current[position]
        if ordinal + 1 < count and r > 0:
            var position = r
            while Int(current[position - 1]) == n - 1: position -= 1
            position -= 1
            current[position] += 1
            for suffix in range(position + 1, r): current[suffix] = current[position]
    return byte_count

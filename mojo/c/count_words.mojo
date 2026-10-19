from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn count_words_trim(c: Int64) -> Bool: return c <= 32
fn count_words_space(c: Int64) -> Bool: return c == 9 or c == 10 or c == 11 or c == 12 or c == 13 or c == 32

@export("count_words")
fn count_words(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < 0 or values[i] > 127: return -1
    if length == 0: return 0
    var start: Int64 = 0
    var end = Int64(length)
    while start < end and count_words_trim(values[start]): start += 1
    while end > start and count_words_trim(values[end - 1]): end -= 1
    if start == end: return 1
    var count: Int64 = 0
    var in_word = False
    for i in range(start, end):
        if count_words_space(values[i]): in_word = False
        elif not in_word:
            count += 1
            in_word = True
    return count

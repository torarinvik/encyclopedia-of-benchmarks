from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn sentence_trim_byte(value: Int64) -> Bool:
    return value == 0 or value == 9 or value == 10 or value == 11 or value == 13 or value == 32

fn sentence_regex_space(value: Int64) -> Bool:
    return (value >= 9 and value <= 13) or value == 32

fn sentence_word_byte(value: Int64) -> Bool:
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122) or (value >= 48 and value <= 57) or value == 95

fn sentence_terminator(value: Int64) -> Bool:
    return value == 46 or value == 33 or value == 63

@export("count_sentences")
fn count_sentences(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4097 or input[0] < 0 or input[0] > 4096 or length != input[0] + 1: return -1
    let text_length = input[0]
    for i in range(text_length):
        if input[i + 1] < 0 or input[i + 1] > 127: return -1
    var begin: Int64 = 0
    var end = text_length
    while begin < end and sentence_trim_byte(input[begin + 1]): begin += 1
    while end > begin and sentence_trim_byte(input[end]): end -= 1
    var cursor = begin
    var count: Int64 = 0
    while cursor + 1 < end:
        var found = False
        for index in range(cursor, end - 1):
            let predecessor = input[index + 1]
            let current = input[index + 2]
            if not sentence_regex_space(predecessor) and predecessor != 124 and predecessor != 94 and predecessor != 46 and sentence_terminator(current) and (index + 2 == end or not sentence_word_byte(input[index + 3])):
                count += 1
                cursor = index + 2
                found = True
                break
        if not found: break
    return count

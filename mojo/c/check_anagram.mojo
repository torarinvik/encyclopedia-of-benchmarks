from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn letter_index(value: Int64) -> Int64:
    if value >= 97 and value <= 122: return value - 97
    if value >= 65 and value <= 90: return value - 65
    return -1

@export("check_anagram")
fn check_anagram(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 2050: return -1
    let first_length = input[0]
    let second_length = input[1]
    if first_length < 0 or first_length > 1024 or second_length < 0 or second_length > 1024 or length != 2 + first_length + second_length: return -1
    var first_counts = InlineArray[Int64, 26](0)
    var second_counts = InlineArray[Int64, 26](0)
    for i in range(first_length):
        let letter = letter_index(input[2 + i])
        if letter < 0: return -1
        first_counts[letter] += 1
    for i in range(second_length):
        let letter = letter_index(input[2 + first_length + i])
        if letter < 0: return -1
        second_counts[letter] += 1
    if first_length != second_length: return 0
    var different_after_normalization = False
    for i in range(first_length):
        if letter_index(input[2 + i]) != letter_index(input[2 + first_length + i]): different_after_normalization = True
    if not different_after_normalization: return 0
    for letter in range(26):
        if first_counts[letter] != second_counts[letter]: return 0
    return 1

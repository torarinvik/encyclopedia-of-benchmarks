from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("can_string_be_rearranged_as_palindrome")
fn can_string_be_rearranged_as_palindrome(text: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length == 0 or length > 4096 or text == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var counts = InlineArray[Int64, 26](0)
    var odd_count: Int64 = 0
    for i in range(length):
        if text[i] < 97 or text[i] > 122: return -1
        let letter = text[i] - 97
        if counts[letter] % 2 == 0: odd_count += 1
        else: odd_count -= 1
        counts[letter] += 1
    return 1 if odd_count <= 1 else 0

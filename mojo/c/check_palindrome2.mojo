from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn lower_ascii(value: Int64) -> Int64:
    return value + 32 if value >= 65 and value <= 90 else value

@export("check_palindrome2")
fn check_palindrome2(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < 32 or values[i] > 126: return -1
    var start: Int64 = 0
    var end = Int64(length)
    while start < end and values[start] == 32: start += 1
    while end > start and values[end - 1] == 32: end -= 1
    let normalized_length = end - start
    if normalized_length == 0 or (normalized_length == 1 and values[start] == 48): return -1
    var palindrome = True
    for left in range(normalized_length // 2):
        let right = normalized_length - left - 1
        if lower_ascii(values[start + left]) != lower_ascii(values[start + right]): palindrome = False
    let suffix_length: Int64 = 24 if palindrome else 28
    let result_length = normalized_length + suffix_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < result_length: return -2
    var staged = InlineArray[UInt8, 1052](0)
    for i in range(normalized_length): staged[i] = UInt8(lower_ascii(values[start + i]))
    if palindrome:
        let suffix = " - a palindrome string.\n"
        for i in range(24): staged[normalized_length + i] = suffix.as_bytes()[i]
    else:
        let suffix = " - not a palindrome string.\n"
        for i in range(28): staged[normalized_length + i] = suffix.as_bytes()[i]
    for i in range(result_length): output[i] = staged[i]
    return result_length

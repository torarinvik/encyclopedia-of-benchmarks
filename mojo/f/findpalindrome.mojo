from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn findpal_punctuation(c: Int64) -> Bool:
    return (c >= 33 and c <= 47) or (c >= 58 and c <= 64) or (c >= 91 and c <= 96) or (c >= 123 and c <= 126)
fn findpal_fold(c: Int64) -> Int64: return c + 32 if c >= 65 and c <= 90 else c

@export("findpalindrome")
fn findpalindrome(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if input[i] < 32 or input[i] > 126: return -1
    var stage = InlineArray[UInt8, 4096](0)
    var written: Int64 = 0
    var segment: Int64 = 0
    var found = False
    for end in range(length + 1):
        if end < length and input[end] != 32: continue
        var token_len: Int64 = 0
        for i in range(segment, end):
            if not findpal_punctuation(input[i]): token_len += 1
        var left = segment
        var right = end
        while left < right:
            while left < right and findpal_punctuation(input[left]): left += 1
            while left < right and findpal_punctuation(input[right - 1]): right -= 1
            if left >= right: break
            if findpal_fold(input[left]) != findpal_fold(input[right - 1]):
                token_len = 0
                break
            left += 1
            right -= 1
        if token_len > 1:
            if found: stage[written] = 0; written += 1
            for i in range(segment, end):
                if not findpal_punctuation(input[i]): stage[written] = UInt8(input[i]); written += 1
            found = True
        segment = end + 1
    if written == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < written: return -2
    for i in range(written): output[i] = stage[i]
    return written

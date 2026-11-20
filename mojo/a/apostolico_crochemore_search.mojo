from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("apostolico_crochemore_search")
fn apostolico_crochemore_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4227:
        return -1
    if input[0] < 0 or input[0] > 4096 or input[1] < 1 or input[1] > 128:
        return -1

    let text_length = Int(input[0])
    let pattern_length = Int(input[1])
    let pattern_start = 2 + text_length
    if length != c_size_t(2 + text_length + pattern_length):
        return -1
    for index in range(2, Int(length)):
        if input[index] < 0 or input[index] > 3:
            return -1

    var kmp_next = InlineArray[Int, 129](fill=0)
    kmp_next[0] = -1
    var preprocess_index = 0
    var border = -1
    while preprocess_index < pattern_length:
        while border > -1 and input[pattern_start + preprocess_index] != input[pattern_start + border]:
            border = kmp_next[border]
        preprocess_index += 1
        border += 1
        if preprocess_index < pattern_length and input[pattern_start + preprocess_index] == input[pattern_start + border]:
            kmp_next[preprocess_index] = kmp_next[border]
        else:
            kmp_next[preprocess_index] = border

    var ell = 1
    while ell < pattern_length and input[pattern_start + ell - 1] == input[pattern_start + ell]:
        ell += 1
    if ell == pattern_length:
        ell = 0

    var i = ell
    var j = 0
    var k = 0
    var match_count: Int64 = 0
    var sum_offsets: Int64 = 0
    var xor_offsets: Int64 = 0
    while j <= text_length - pattern_length:
        while i < pattern_length and input[pattern_start + i] == input[2 + j + i]:
            i += 1
        if i >= pattern_length:
            while k < ell and input[pattern_start + k] == input[2 + j + k]:
                k += 1
            if k >= ell:
                match_count += 1
                sum_offsets += Int64(j)
                xor_offsets ^= Int64(j)

        j += i - kmp_next[i]
        if i == ell:
            if k > 0:
                k -= 1
        elif kmp_next[i] <= ell:
            k = kmp_next[i]
            if k < 0:
                k = 0
            i = ell
        else:
            k = ell
            i = kmp_next[i]

    return match_count * 68719476736 + sum_offsets * 4096 + xor_offsets

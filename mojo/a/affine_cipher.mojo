from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn affine_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = a0
    var b = b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    return a

@export("affine_cipher")
fn affine_cipher(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 612:
        return -1
    let mode = values[0]
    let a = values[1]
    let b = values[2]
    let alphabet_len = values[3]
    if mode < 0 or mode > 1 or alphabet_len < 2 or alphabet_len > 95:
        return -1
    let text_len_slot = 4 + alphabet_len
    if length <= c_size_t(text_len_slot):
        return -1
    let text_len = values[text_len_slot]
    if a < 0 or a > 1000000 or b < 0 or b >= alphabet_len or text_len < 0 or text_len > 512 or length != c_size_t(text_len_slot + 1 + text_len) or affine_gcd(a, alphabet_len) != 1:
        return -1
    var positions = List[Int64](length=128, fill=-1)
    for i in range(alphabet_len):
        let ch = values[4 + i]
        if ch < 32 or ch > 126 or positions[Int(ch)] != -1:
            return -1
        positions[Int(ch)] = i
    for i in range(text_len):
        let ch = values[text_len_slot + 1 + i]
        if ch < 32 or ch > 126 or positions[Int(ch)] < 0:
            return -1
    if capacity < c_size_t(text_len) or (text_len > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    var inverse: Int64 = 0
    if mode == 1:
        var candidate: Int64 = 1
        while candidate < alphabet_len:
            if (a % alphabet_len * candidate) % alphabet_len == 1:
                inverse = candidate
                break
            candidate += 1
    for i in range(text_len):
        let ch = values[text_len_slot + 1 + i]
        let p = positions[Int(ch)]
        var mapped: Int64 = 0
        if mode == 0:
            mapped = (p * (a % alphabet_len) + b) % alphabet_len
        else:
            mapped = (((p - b + alphabet_len) % alphabet_len) * inverse) % alphabet_len
        output[i] = UInt8(values[4 + mapped])
    return text_len

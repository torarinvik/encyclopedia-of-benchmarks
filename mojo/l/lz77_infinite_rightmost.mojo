# Greedy infinite-window LZ77 with rightmost match ties.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("lz77_infinite_rightmost")
fn lz77_infinite_rightmost(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(nv + 1): return -1
    let n = Int(nv)
    var text = List[Int64](capacity=n)
    for i in range(n):
        let character = input[1+i]
        if character < 32 or character > 126: return -1
        text.append(character)
    var fields = List[Int64](capacity=3*n)
    var q = 0
    while q < n:
        var best_length = 0
        var best_position = 0
        for p in range(q):
            var matched = 0
            while q + matched < n and text[p+matched] == text[q+matched]:
                matched += 1
            if matched > best_length or (matched == best_length and matched > 0 and p > best_position):
                best_length = matched
                best_position = p
        let next_position = q + best_length
        var next_character = Int64(0)
        if next_position < n: next_character = text[next_position]
        fields.append(Int64(best_position))
        fields.append(Int64(best_length))
        fields.append(next_character)
        q = next_position
        if next_character != 0: q += 1
    let bytes = 8 * len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)

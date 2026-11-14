# Modified independent bounded Ispell lookup profile; see the package license.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bucket(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, length: Int, size: Int) -> Int:
    var value = UInt32(0)
    for i in range(length):
        let ch = UInt32(input[start+i] - 32)
        if i < 4:
            value = (value << 8) | ch
        else:
            value = ((value << 5) | (value >> 27)) ^ ch
    return Int(UInt64(value) % UInt64(size))

@export("cbench_ispell_lookup_chain")
fn cbench_ispell_lookup_chain(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 108: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or input[2] < 0 or input[2] > 8: return -1
    let size = Int(input[0])
    let query_length = Int(input[1])
    let count = Int(input[2])
    let heads = 3 + query_length
    let next = heads + size
    let lengths = next + count
    var cursor = lengths + count
    if length < c_size_t(cursor): return -1
    for i in range(query_length):
        if input[3+i] < 97 or input[3+i] > 122: return -1
    for i in range(size):
        if input[heads+i] < -1 or input[heads+i] >= Int64(count): return -1
    var offsets = List[Int](capacity=8)
    var sizes = List[Int](capacity=8)
    for i in range(count):
        if input[next+i] < -1 or input[next+i] >= Int64(count): return -1
        let word_length = input[lengths+i]
        if word_length < 1 or word_length > 8 or cursor + Int(word_length) > Int(length): return -1
        offsets.append(cursor)
        sizes.append(Int(word_length))
        for j in range(Int(word_length)):
            if input[cursor+j] < 97 or input[cursor+j] > 122: return -1
        cursor += Int(word_length)
    if cursor != Int(length): return -1
    var seen = List[Bool](capacity=8)
    for _ in range(count): seen.append(False)
    var reached = 0
    for b in range(size):
        var entry = input[heads+b]
        while entry != -1:
            let i = Int(entry)
            if seen[i]: return -1
            seen[i] = True
            reached += 1
            if bucket(input, offsets[i], sizes[i], size) != b: return -1
            entry = input[next+i]
    if reached != count: return -1
    var entry = input[heads + bucket(input, 3, query_length, size)]
    while entry != -1:
        let i = Int(entry)
        var matches = sizes[i] == query_length
        if matches:
            for j in range(query_length):
                if input[offsets[i]+j] != input[3+j]: matches = False
        if matches: return entry + 1
        entry = input[next+i]
    return 0

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("anagram_dictionary_search")
fn anagram_dictionary_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 16 or input[1] < 0 or input[1] > 16:
        return -1
    let count = Int(input[0])
    let qlen = Int(input[1])
    if 2 + qlen > Int(length): return -1
    var query_counts = List[Int](length=26, fill=0)
    for i in range(qlen):
        let ch = input[2 + i]
        if ch < 97 or ch > 122: return -1
        query_counts[Int(ch - 97)] += 1
    var offset = 2 + qlen
    var encoded = List[UInt8](capacity=273)
    for word in range(count):
        if offset >= Int(length) or input[offset] < 1 or input[offset] > 16: return -1
        let wlen = Int(input[offset])
        offset += 1
        if offset + wlen > Int(length): return -1
        var word_counts = List[Int](length=26, fill=0)
        for i in range(wlen):
            let ch = input[offset + i]
            if ch < 97 or ch > 122: return -1
            word_counts[Int(ch - 97)] += 1
        var same = wlen == qlen
        for i in range(26):
            if query_counts[i] != word_counts[i]: same = False
        if same:
            for i in range(wlen): encoded.append(UInt8(input[offset + i]))
            encoded.append(10)
        offset += wlen
    if offset != Int(length): return -1
    encoded.append(0)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(encoded)):
        return -2
    for i in range(len(encoded)): output[i] = encoded[i]
    return Int64(len(encoded))

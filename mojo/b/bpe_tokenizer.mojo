from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("bpe_tokenizer")
fn bpe_tokenizer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 514: return -2
    let merges = input[0]; let bv = input[1]
    if merges < 0 or merges > 32 or bv < 0 or bv > 512 or length != c_size_t(2 + bv): return -2
    let n = Int(bv); var tokens = List[Int](capacity=512)
    for i in range(n):
        if input[2 + i] < 0 or input[2 + i] > 255: return -2
        tokens.append(Int(input[2 + i]))
    for step in range(Int(merges)):
        let count = len(tokens)
        if count <= 1: break
        var lefts = List[Int](capacity=count - 1); var rights = List[Int](capacity=count - 1); var freqs = List[Int](capacity=count - 1)
        for i in range(count - 1):
            var p = 0
            while p < len(lefts) and (lefts[p] != tokens[i] or rights[p] != tokens[i + 1]): p += 1
            if p == len(lefts): lefts.append(tokens[i]); rights.append(tokens[i + 1]); freqs.append(1)
            else: freqs[p] += 1
        var best = 0
        for i in range(1, len(freqs)):
            if freqs[i] > freqs[best]: best = i
        if len(freqs) == 0 or freqs[best] == 1: break
        var next = List[Int](capacity=512); var i = 0
        while i < count:
            if i + 1 < count and tokens[i] == lefts[best] and tokens[i + 1] == rights[best]:
                next.append(256 + step); i += 2
            else: next.append(tokens[i]); i += 1
        tokens = next
    let needed = len(tokens) * 2
    if needed > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed)): return -2
    for i in range(len(tokens)):
        output[2 * i] = UInt8(tokens[i] & 255); output[2 * i + 1] = UInt8((tokens[i] >> 8) & 255)
    return Int64(len(tokens))

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_WAYS = 4096
comptime MAX_TARGET = 6

@export("all_construct")
fn all_construct(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > MAX_TARGET:
        return -1
    let n = Int(input[0])
    for i in range(n):
        if input[i + 1] < 97 or input[i + 1] > 122:
            return -1
    let word_slot = 1 + n
    if word_slot >= Int(length) or input[word_slot] < 0 or input[word_slot] > 4:
        return -1
    let word_count = Int(input[word_slot])
    var starts = List[Int](length=4, fill=0)
    var word_lengths = List[Int](length=4, fill=0)
    var cursor = word_slot + 1
    for w in range(word_count):
        if cursor >= Int(length) or input[cursor] < 1 or input[cursor] > MAX_TARGET:
            return -1
        let wl = Int(input[cursor])
        cursor += 1
        if cursor + wl > Int(length):
            return -1
        starts[w] = cursor
        word_lengths[w] = wl
        for j in range(wl):
            if input[cursor + j] < 97 or input[cursor + j] > 122:
                return -1
        cursor += wl
    if cursor != Int(length):
        return -1
    var paths = List[Int64](length=(MAX_TARGET + 1) * MAX_WAYS * MAX_TARGET, fill=0)
    var path_lengths = List[Int](length=(MAX_TARGET + 1) * MAX_WAYS, fill=0)
    var counts = List[Int](length=MAX_TARGET + 1, fill=0)
    counts[0] = 1
    for pos in range(n):
        for w in range(word_count):
            let wl = word_lengths[w]
            if wl > n - pos:
                continue
            var j = 0
            while j < wl and input[pos + 1 + j] == input[starts[w] + j]:
                j += 1
            if j != wl:
                continue
            let end = pos + wl
            for r in range(counts[pos]):
                let dest = counts[end]
                if dest >= MAX_WAYS:
                    return -1
                counts[end] += 1
                let oldlen = path_lengths[pos * MAX_WAYS + r]
                for k in range(oldlen):
                    paths[(end * MAX_WAYS + dest) * MAX_TARGET + k] = paths[(pos * MAX_WAYS + r) * MAX_TARGET + k]
                paths[(end * MAX_WAYS + dest) * MAX_TARGET + oldlen] = Int64(w)
                path_lengths[end * MAX_WAYS + dest] = oldlen + 1
    var required = 0
    for r in range(counts[n]):
        required += 1
        let plen = path_lengths[n * MAX_WAYS + r]
        for k in range(plen):
            let w = Int(paths[(n * MAX_WAYS + r) * MAX_TARGET + k])
            required += 1 + word_lengths[w]
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    var out = 0
    for r in range(counts[n]):
        let plen = path_lengths[n * MAX_WAYS + r]
        output[out] = UInt8(plen)
        out += 1
        for k in range(plen):
            let w = Int(paths[(n * MAX_WAYS + r) * MAX_TARGET + k])
            output[out] = UInt8(word_lengths[w])
            out += 1
            for j in range(word_lengths[w]):
                output[out] = UInt8(input[starts[w] + j])
                out += 1
    return Int64(counts[n])

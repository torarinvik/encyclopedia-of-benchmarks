from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn aho_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[pos + b] = UInt8((bits >> (8 * b)) & 255)

@export("aho_corasick")
fn aho_corasick(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 256:
        return -1
    let patterns = Int(input[0])
    let text_len = Int(input[1])
    if length < c_size_t(2 + patterns):
        return -1
    var starts = List[Int](length=patterns, fill=0)
    var total = 2 + patterns
    for p in range(patterns):
        let plen = input[2 + p]
        if plen < 1 or plen > 32 or total + Int(plen) > Int(length):
            return -1
        starts[p] = total
        for i in range(Int(plen)):
            if input[starts[p] + i] < 1 or input[starts[p] + i] > 127:
                return -1
        for q in range(p):
            if input[2 + q] != plen:
                continue
            var i = 0
            while i < Int(plen) and input[starts[q] + i] == input[starts[p] + i]:
                i += 1
            if i == Int(plen):
                return -1
        total += Int(plen)
    let text_start = total
    if total + text_len != Int(length):
        return -1
    for i in range(text_len):
        if input[text_start + i] < 1 or input[text_start + i] > 127:
            return -1
    let out_bytes = patterns * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(out_bytes):
        return -2
    let max_nodes = 1 + patterns * 32
    var next = List[Int](length=max_nodes * 128, fill=-1)
    var failure = List[Int](length=max_nodes, fill=0)
    var terminal = List[Int](length=max_nodes, fill=-1)
    var nodes = 1
    for p in range(patterns):
        var state = 0
        let plen = Int(input[2 + p])
        for i in range(plen):
            let ch = Int(input[starts[p] + i])
            let ix = state * 128 + ch
            if next[ix] == -1:
                next[ix] = nodes
                nodes += 1
            state = next[ix]
        terminal[state] = p
    var queue = List[Int](capacity=max_nodes)
    for ch in range(1, 128):
        let child = next[ch]
        if child != -1:
            queue.append(child)
    var head = 0
    while head < len(queue):
        let state = queue[head]
        head += 1
        for ch in range(1, 128):
            let child = next[state * 128 + ch]
            if child == -1:
                continue
            var suffix = failure[state]
            while suffix != 0 and next[suffix * 128 + ch] == -1:
                suffix = failure[suffix]
            if next[suffix * 128 + ch] != -1:
                suffix = next[suffix * 128 + ch]
            failure[child] = suffix
            queue.append(child)
    var counts = List[Int64](length=patterns, fill=0)
    var state = 0
    for i in range(text_len):
        let ch = Int(input[text_start + i])
        while state != 0 and next[state * 128 + ch] == -1:
            state = failure[state]
        if next[state * 128 + ch] != -1:
            state = next[state * 128 + ch]
        var match = state
        while match != 0:
            if terminal[match] >= 0:
                counts[terminal[match]] += 1
            match = failure[match]
    for p in range(patterns):
        aho_write_i64(output, 8 * p, counts[p])
    return Int64(out_bytes)

from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("longest_common_substring_sam")
fn longest_common_substring_sam(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 515: return -1
    if input[0] < 0 or input[0] > 256: return -1
    let n = Int(input[0])
    if length < c_size_t(n+2) or input[n+1] < 0 or input[n+1] > 256: return -1
    let m = Int(input[n+1])
    if length != c_size_t(n+m+2): return -1
    for i in range(n):
        if input[1+i] < 32 or input[1+i] > 126: return -1
    for i in range(m):
        if input[n+2+i] < 32 or input[n+2+i] > 126: return -1
    var edges = InlineArray[Int32, 48735](fill=-1)
    var links = InlineArray[Int32, 513](fill=-1)
    var lens = InlineArray[Int, 513](fill=0)
    var size = 1
    var last = 0
    for i in range(n):
        let symbol = Int(input[1+i]-32)
        let current = size
        size += 1
        lens[current] = lens[last]+1
        var p = last
        while p >= 0 and edges[95*p+symbol] < 0:
            edges[95*p+symbol] = Int32(current)
            p = Int(links[p])
        if p < 0: links[current] = 0
        else:
            let q = Int(edges[95*p+symbol])
            if lens[p]+1 == lens[q]: links[current] = Int32(q)
            else:
                let clone = size
                size += 1
                for a in range(95): edges[95*clone+a] = edges[95*q+a]
                links[clone] = links[q]
                lens[clone] = lens[p]+1
                while p >= 0 and edges[95*p+symbol] == Int32(q):
                    edges[95*p+symbol] = Int32(clone)
                    p = Int(links[p])
                links[q] = Int32(clone)
                links[current] = Int32(clone)
        last = current
    var state = 0
    var matched = 0
    var best = 0
    for i in range(m):
        let symbol = Int(input[n+2+i]-32)
        while state != 0 and edges[95*state+symbol] < 0:
            state = Int(links[state])
            matched = lens[state]
        let next = Int(edges[95*state+symbol])
        if next < 0:
            state = 0
            matched = 0
        else:
            state = next
            matched += 1
            if matched > best: best = matched
    return Int64(best)

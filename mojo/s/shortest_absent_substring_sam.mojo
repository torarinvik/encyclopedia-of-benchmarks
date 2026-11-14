from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("shortest_absent_substring_sam")
fn shortest_absent_substring_sam(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    if input[0] < 2 or input[0] > 4 or input[1] < 0 or input[1] > 64: return -1
    let alphabet = Int(input[0])
    let n = Int(input[1])
    if length != c_size_t(2+n): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] >= Int64(alphabet): return -1
    var edges = InlineArray[Int, 516](fill=-1)
    var links = InlineArray[Int, 129](fill=-1)
    var lens = InlineArray[Int, 129](fill=0)
    var size = 1
    var last = 0
    for i in range(n):
        let symbol = Int(input[2+i])
        let current = size
        size += 1
        lens[current] = lens[last]+1
        var p = last
        while p >= 0 and edges[4*p+symbol] < 0:
            edges[4*p+symbol] = current
            p = links[p]
        if p < 0: links[current] = 0
        else:
            let q = edges[4*p+symbol]
            if lens[p]+1 == lens[q]: links[current] = q
            else:
                let clone = size
                size += 1
                for a in range(4): edges[4*clone+a] = edges[4*q+a]
                links[clone] = links[q]
                lens[clone] = lens[p]+1
                while p >= 0 and edges[4*p+symbol] == q:
                    edges[4*p+symbol] = clone
                    p = links[p]
                links[q] = clone
                links[current] = clone
        last = current
    var counts = InlineArray[Int, 65](fill=0)
    var order = InlineArray[Int, 129](fill=0)
    var dp = InlineArray[Int, 129](fill=0)
    for s in range(size): counts[lens[s]] += 1
    for i in range(1, n+1): counts[i] += counts[i-1]
    for offset in range(size):
        let s = size-1-offset
        counts[lens[s]] -= 1
        order[counts[lens[s]]] = s
    for offset in range(size):
        let s = order[size-1-offset]
        var best = 100
        for a in range(alphabet):
            let child = edges[4*s+a]
            var candidate = 1
            if child >= 0: candidate += dp[child]
            if candidate < best: best = candidate
        dp[s] = best
    var result = InlineArray[UInt8, 6](fill=0)
    var count = 0
    var state = 0
    while state >= 0:
        for a in range(alphabet):
            let child = edges[4*state+a]
            var eligible = child < 0 and dp[state] == 1
            if child >= 0: eligible = dp[state] == 1+dp[child]
            if eligible:
                result[count] = UInt8(a)
                count += 1
                state = child
                break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = result[i]
    return Int64(count)

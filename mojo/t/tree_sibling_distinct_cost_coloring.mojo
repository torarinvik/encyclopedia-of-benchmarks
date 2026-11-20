# Independent bounded subset-assignment draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tree_sibling_distinct_cost_coloring")
fn tree_sibling_distinct_cost_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 354: return -1
    if input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 10: return -1
    let n = Int(input[0]); let k = Int(input[1])
    if length != c_size_t(n+1+n*k): return -1
    for vertex in range(1,n):
        if input[1+vertex] < 0 or input[1+vertex] >= Int64(vertex): return -1
    for i in range(n*k):
        if input[n+1+i] < 0 or input[n+1+i] > 1000000: return -1
    let inf = Int64(1000000000000)
    let states = 1 << k
    var dp = InlineArray[Int64, 320](fill=0)
    var current = InlineArray[Int64, 1024](fill=0)
    var next = InlineArray[Int64, 1024](fill=0)
    var vertex = n
    while vertex > 0:
        vertex -= 1
        for color in range(k):
            for mask in range(states): current[mask] = inf
            current[1 << color] = 0
            for child in range(vertex+1,n):
                if input[1+child] != Int64(vertex): continue
                for mask in range(states): next[mask] = inf
                for mask in range(states):
                    if current[mask] == inf: continue
                    for c in range(k):
                        let bit = 1 << c
                        if (mask & bit) != 0 or dp[10*child+c] == inf: continue
                        let extended = mask | bit
                        let candidate = current[mask]+dp[10*child+c]
                        if candidate < next[extended]: next[extended] = candidate
                for mask in range(states): current[mask] = next[mask]
            var best = inf
            for mask in range(states):
                if current[mask] < best: best = current[mask]
            dp[10*vertex+color] = inf if best == inf else best+input[n+1+vertex*k+color]
    var best = inf
    for color in range(k):
        if dp[color] < best: best = dp[color]
    return -2 if best == inf else best

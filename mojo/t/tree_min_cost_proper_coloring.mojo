# Uncompiled bounded minimum-cost proper tree coloring draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tree_min_cost_proper_coloring")
fn tree_min_cost_proper_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<2 or length>1090: return -1
    let nv=input[0]
    let kv=input[1]
    if nv<1 or nv>64 or kv<1 or kv>16: return -1
    let n=Int(nv)
    let k=Int(kv)
    if length!=c_size_t(n+1+n*k): return -1
    for v in range(1,n):
        if input[1+v]<0 or input[1+v]>=Int64(v): return -1
    var dp=InlineArray[Int64,1024](fill=0)
    for v in range(n):
        for color in range(k):
            let value=input[n+1+v*k+color]
            if value<0 or value>1000000: return -1
            dp[16*v+color]=value
    if n>1 and k==1: return -2
    var child=n-1
    while child>0:
        let parent=Int(input[1+child])
        var least: Int64=64000001
        var second: Int64=64000001
        var best_color=0
        for color in range(k):
            let value=dp[16*child+color]
            if value<least:
                second=least
                least=value
                best_color=color
            elif value<second: second=value
        for color in range(k):
            let addition=second if color==best_color else least
            dp[16*parent+color]+=addition
        child-=1
    var best=dp[0]
    for color in range(1,k):
        if dp[color]<best: best=dp[color]
    return best

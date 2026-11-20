# Uncompiled minimum-weight tree edge-domination draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn tweds_min(a: Int64, b: Int64) -> Int64:
    return a if a < b else b

@export("tree_weighted_edge_dominating_set")
fn tree_weighted_edge_dominating_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 128: return -1
    let nv = input[0]
    if nv < 1 or nv > 64 or length != c_size_t(2*nv-1): return -1
    let n = Int(nv)
    for v in range(1,n):
        if input[v] < 0 or input[v] >= Int64(v) or input[n+v-1] < 0 or input[n+v-1] > 1000000: return -1
    let inf = Int64(1000000000000)
    var selected = InlineArray[Int64,64](fill=inf)
    var closed = InlineArray[Int64,64](fill=0)
    var pending = InlineArray[Int64,64](fill=0)
    var v = n-1
    while v > 0:
        let p = Int(input[v])
        let skip = tweds_min(selected[v], closed[v])
        let take = input[n+v-1] + tweds_min(selected[v], pending[v])
        selected[p] = tweds_min(inf, tweds_min(selected[p] + tweds_min(skip, take), pending[p] + take))
        closed[p] = tweds_min(inf, closed[p] + selected[v])
        pending[p] = tweds_min(inf, pending[p] + skip)
        v -= 1
    return tweds_min(selected[0], closed[0])

# Uncompiled minimum tree path-partition draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tree_minimum_path_partition")
fn tree_minimum_path_partition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let nv = input[0]
    if nv < 1 or nv > 64 or length != c_size_t(nv): return -1
    let n = Int(nv)
    for v in range(1,n):
        if input[v] < 0 or input[v] >= Int64(v): return -1
    var base = InlineArray[Int64,64](fill=0)
    var first = InlineArray[Int64,64](fill=0)
    var second = InlineArray[Int64,64](fill=0)
    var v = n-1
    while v > 0:
        let p = Int(input[v])
        let best = base[v] + first[v] + second[v]
        let gain = 1 + base[v] + first[v] - best
        base[p] += best
        if gain > first[p]:
            second[p] = first[p]
            first[p] = gain
        elif gain > second[p]:
            second[p] = gain
        v -= 1
    return nv - base[0] - first[0] - second[0]

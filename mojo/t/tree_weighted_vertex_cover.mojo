# Uncompiled weighted tree vertex-cover draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tree_weighted_vertex_cover")
fn tree_weighted_vertex_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<2 or length>129: return -1
    let nv=input[0]
    if nv<1 or nv>64 or length!=c_size_t(2*nv): return -1
    let n=Int(nv)
    for v in range(1,n):
        if input[v]<0 or input[v]>=Int64(v): return -1
    var included=InlineArray[Int64,64](fill=0)
    var excluded=InlineArray[Int64,64](fill=0)
    for v in range(n):
        let weight=input[n+v]
        if weight<0 or weight>1000000: return -1
        included[v]=weight
    var v=n-1
    while v>0:
        let parent=Int(input[v])
        included[parent]+=included[v] if included[v]<excluded[v] else excluded[v]
        excluded[parent]+=included[v]
        v-=1
    return included[0] if included[0]<excluded[0] else excluded[0]

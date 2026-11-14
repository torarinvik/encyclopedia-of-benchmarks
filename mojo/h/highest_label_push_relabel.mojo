from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("highest_label_push_relabel")
fn highest_label_push_relabel(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<4 or length>197: return -1
    let nv=input[0]
    let mv=input[1]
    let sv=input[2]
    let tv=input[3]
    if nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv: return -1
    let n=Int(nv)
    let m=Int(mv)
    let source=Int(sv-1)
    let sink=Int(tv-1)
    if length != c_size_t(4+3*m): return -1
    var residual=InlineArray[Int64,256](fill=0)
    var excess=InlineArray[Int64,16](fill=0)
    var height=InlineArray[Int,16](fill=0)
    for i in range(m):
        let u=input[4+3*i]
        let v=input[5+3*i]
        let capacity=input[6+3*i]
        if u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100: return -1
        residual[16*Int(u-1)+Int(v-1)] += capacity
    height[source]=n
    for v in range(n):
        let amount=residual[16*source+v]
        residual[16*source+v]=0
        residual[16*v+source]+=amount
        excess[v]+=amount
        excess[source]-=amount
    while True:
        var active = -1
        for v in range(n):
            if v!=source and v!=sink and excess[v]>0:
                if active<0: active=v
                elif height[v]>height[active]: active=v
        if active<0: return excess[sink]
        var destination = -1
        var minimum=2*n+1
        for v in range(n):
            if residual[16*active+v]>0:
                if height[v]<minimum: minimum=height[v]
                if destination<0 and height[active]==height[v]+1: destination=v
        if destination<0:
            if minimum>2*n: return -1
            height[active]=minimum+1
        else:
            var amount=excess[active]
            if residual[16*active+destination]<amount: amount=residual[16*active+destination]
            residual[16*active+destination]-=amount
            residual[16*destination+active]+=amount
            excess[active]-=amount
            excess[destination]+=amount

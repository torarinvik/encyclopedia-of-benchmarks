from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("stoer_wagner")
fn stoer_wagner(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let nv=v[0]
    if nv<2 or nv>16 or n!=c_size_t(1+nv*nv):return -1
    let count=Int(nv);var graph=InlineArray[Int64,256](fill=0)
    for i in range(count*count):
        let w=v[i+1]
        if w<0 or w>1000000:return -1
        graph[i]=w
    for r in range(count):
        if graph[r*count+r]!=0:return -1
        for c in range(r+1,count):if graph[r*count+c]!=graph[c*count+r]:return -1
    var merged=InlineArray[Bool,16](fill=False);var mincut:Int64=120000001
    for phase in range(count-1):
        var inside=InlineArray[Bool,16](fill=False);var weights=InlineArray[Int64,16](fill=0);var previous= -1;var last= -1
        for _ in range(count-phase):
            var current= -1;var best:Int64= -1
            for u in range(count):
                if not merged[u] and not inside[u] and weights[u]>best:best=weights[u];current=u
            if current<0:break
            inside[current]=True;previous=last;last=current
            for u in range(count):if not merged[u] and not inside[u]:weights[u]+=graph[current*count+u]
        if last<0 or previous<0:return -1
        if weights[last]<mincut:mincut=weights[last]
        for u in range(count):graph[previous*count+u]+=graph[last*count+u];graph[u*count+previous]=graph[previous*count+u]
        merged[last]=True
    return mincut

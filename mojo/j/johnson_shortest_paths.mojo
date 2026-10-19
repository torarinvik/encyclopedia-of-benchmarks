from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn jh_mix(h0:UInt64,x0:Int64)->UInt64:
    var h=h0;let x=bitcast[UInt64](x0)
    for b in range(8):h=(h^((x>>UInt64(8*b))&255))*UInt64(1099511628211)
    return h
@export("johnson_shortest_paths")
fn johnson_shortest_paths(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>770:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if count<1 or count>32 or edges<0 or edges>256 or n!=c_size_t(2+3*edges):return -1
    var fr=InlineArray[Int,256](fill=0);var to=InlineArray[Int,256](fill=0);var wt=InlineArray[Int64,256](fill=0)
    for e in range(edges):
        let a=v[2+3*e];let b=v[3+3*e];let w=v[4+3*e]
        if a<1 or a>count or b<1 or b>count or w< -32 or w>32:return -1
        fr[e]=Int(a-1);to[e]=Int(b-1);wt[e]=w
    var h=InlineArray[Int64,32](fill=0)
    for it in range(1,count):
        var changed=False
        for e in range(edges):
            let cand=h[fr[e]]+wt[e]
            if cand<h[to[e]]:h[to[e]]=cand;changed=True
        if not changed:break
    for e in range(edges):if h[fr[e]]+wt[e]<h[to[e]]:return -1
    var hash=UInt64(14695981039346656037)
    for source in range(count):
        var dist=InlineArray[Int64,32](fill=0);var seen=InlineArray[Bool,32](fill=False);let inf=Int64(9223372036854775807)
        for i in range(count):dist[i]=inf
        dist[source]=0
        var qv=InlineArray[Int,257](fill=0);var qd=InlineArray[Int64,257](fill=0);var qlen=1;qv[0]=source;qd[0]=0
        while qlen>0:
            var min=0
            for i in range(1,qlen):if qd[i]<qd[min]:min=i
            let current=qv[min]
            for i in range(min+1,qlen):qv[i-1]=qv[i];qd[i-1]=qd[i]
            qlen-=1
            if seen[current]:continue
            seen[current]=True
            for e in range(edges):
                if fr[e]==current:
                    let next=to[e];let re=wt[e]+h[current]-h[next];let cand=dist[current]+re
                    if not seen[next] and cand<dist[next]:dist[next]=cand;qv[qlen]=next;qd[qlen]=cand;qlen+=1
        for dest in range(count):
            let result=if dist[dest]==inf then Int64(4611686018427387904) else dist[dest]-h[source]+h[dest]
            hash=jh_mix(hash,result)
    return Int64(hash&UInt64(9223372036854775807))

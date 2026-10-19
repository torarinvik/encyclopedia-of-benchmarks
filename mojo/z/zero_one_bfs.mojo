from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime QCAP=4097
@export("zero_one_bfs")
fn zero_one_bfs(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>3075:return -1
    let nv=v[0];let src=v[1];let ec=v[2]
    if nv<1 or nv>64 or src<0 or src>=nv or ec<0 or ec>1024 or n!=c_size_t(3+3*ec):return -1
    var zero=InlineArray[UInt8,4096](fill=0);var one=InlineArray[UInt8,4096](fill=0)
    for e in range(Int(ec)):
        let at=3+3*e;let a=v[at];let b=v[at+1];let w=v[at+2]
        if a<0 or a>=nv or b<0 or b>=nv or (w!=0 and w!=1):return -1
        if w==0:zero[Int(a)*64+Int(b)]=1
        else:one[Int(a)*64+Int(b)]=1
    var dist=InlineArray[Int,64](fill=255);var deque=InlineArray[Int,4097](fill=0)
    var head=0;var size=1;dist[Int(src)]=0;deque[0]=Int(src)
    while size>0:
        let u=deque[head];head=(head+1)%QCAP;size-=1
        for to in range(Int(nv)):
            if zero[u*64+to]!=0:
                if dist[to]>dist[u]:
                    dist[to]=dist[u];head=(head+QCAP-1)%QCAP;deque[head]=to;size+=1
            if one[u*64+to]!=0:
                if dist[to]>dist[u]+1:
                    dist[to]=dist[u]+1;deque[(head+size)%QCAP]=to;size+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(nv):return -2
    for i in range(Int(nv)):o[i]=UInt8(dist[i])
    return nv

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("priority_queue")
fn priority_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130 or v[0]<0 or v[0]>64:return -1
    let ops=Int(v[0]);var heap=InlineArray[Int32,64](fill=0);var seen=InlineArray[Int32,64](fill=0);var hs=0;var sc=0;var cur=1;var outvals=InlineArray[Int32,64](fill=0);var oc=0
    for _ in range(ops):
        if cur>=Int(n):return -1
        let op=v[cur];cur+=1
        if op==0:
            if cur>=Int(n):return -1
            let raw=v[cur];cur+=1
            if raw< -2147483648 or raw>2147483647:return -1
            for i in range(sc):if seen[i]==Int32(raw):return -1
            seen[sc]=Int32(raw);sc+=1;var i=hs;heap[i]=Int32(raw);hs+=1
            while i>0:
                let p=(i-1)//2
                if heap[p]<=heap[i]:break
                let t=heap[p];heap[p]=heap[i];heap[i]=t;i=p
        elif op==1 or op==2:
            if hs==0:return -1
            outvals[oc]=heap[0];oc+=1
            if op==2:
                hs-=1
                if hs>0:
                    heap[0]=heap[hs];var i=0
                    while 2*i+1<hs:
                        var c=2*i+1
                        if c+1<hs and heap[c+1]<heap[c]:c+=1
                        if heap[i]<=heap[c]:break
                        let t=heap[i];heap[i]=heap[c];heap[c]=t;i=c
        else:return -1
    if cur!=Int(n):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(oc*4):return -2
    for i in range(oc):
        let bits=UInt32(outvals[i])
        for b in range(4):out[i*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(oc*4)

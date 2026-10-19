from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("topological")
fn topological(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or (n-1)%2!=0:return -2
    if a[0]<0 or a[0]>64:return -2
    let nv=Int(a[0]);var dep=InlineArray[Int,64]();var adj=InlineArray[UInt64,64]();var answer=InlineArray[UInt8,96]();var outn=0
    for e in range((Int(n)-1)/2):
        let u=a[1+2*e];let v=a[2+2*e]
        if u<0 or v<0 or u>=nv or v>=nv:return -2
        dep[Int(v)]+=1;adj[Int(u)]=adj[Int(u)]|(UInt64(1)<<UInt64(v))
    for root in range(nv):
        if dep[root]!=0:continue
        var stack=InlineArray[Int,64]();var top=0;stack[top]=root;top+=1
        while top>0:
            top-=1;let u=stack[top];answer[outn]=UInt8(u);outn+=1
            for v in range(nv):
                let mask=UInt64(1)<<UInt64(v)
                if (adj[u]&mask)!=0:
                    var inside=False
                    for j in range(top):
                        if stack[j]==v:inside=True
                    if not inside:stack[top]=v;top+=1
                adj[u]=adj[u]&(~mask);adj[v]=adj[v]&(~(UInt64(1)<<UInt64(u)))
    if cap<c_size_t(outn) or (outn>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(outn):o[i]=answer[i]
    return Int64(outn)

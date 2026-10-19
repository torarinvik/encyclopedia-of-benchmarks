from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("topological_sort_dfs")
fn topological_sort_dfs(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or (n-1)%2!=0 or a[0]<0 or a[0]>40:return -2
    let nv=Int(a[0]);var adj=InlineArray[UInt64,40]()
    for e in range((Int(n)-1)/2):
        let u=a[1+2*e];let v=a[2+2*e]
        if u<0 or v<0 or u>=nv or v>=nv:return -2
        adj[Int(u)]=adj[Int(u)]|(UInt64(1)<<UInt64(v))
    var state=InlineArray[Int,40]();var stack=InlineArray[Int,40]();var next=InlineArray[Int,40]();var order=InlineArray[Int,40]();var count=0
    for root in range(nv):
        if state[root]!=0:continue
        var top=0;stack[0]=root;next[0]=0;state[root]=1
        while True:
            let u=stack[top];var v=next[top]
            while v<nv and (adj[u]&(UInt64(1)<<UInt64(v)))==0:v+=1
            if v==nv:
                state[u]=2;order[count]=u;count+=1
                if top==0:break
                top-=1
            else:
                next[top]=v+1
                if state[v]==1:return -1
                if state[v]==0:top+=1;stack[top]=v;next[top]=0;state[v]=1
    if cap<c_size_t(nv) or (nv>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):o[i]=UInt8(order[count-1-i])
    return Int64(count)

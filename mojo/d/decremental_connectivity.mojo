from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn dec_find(parent:List[Int],x0:Int)->Int:
    var x=x0
    while parent[x]!=x:x=parent[x]
    return x
fn dec_walk(adj:List[Int],n:Int,start:Int,block_u:Int,block_v:Int,mut seen:List[Int],mut members:List[Int])->Int:
    var stack=List[Int](capacity=1024);stack.append(start);var count=0
    while len(stack)>0:
        let last=len(stack)-1;let u=stack[last];stack.pop()
        if seen[u]!=0:continue
        seen[u]=1;members.append(u);count+=1
        for v in range(n):
            if ((adj[u]>>v)&1)!=0 and not ((u==block_u and v==block_v) or (u==block_v and v==block_u)) and seen[v]==0:stack.append(v)
    return count
@export("decremental_connectivity")
fn decremental_connectivity(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>449:return -1
    let nv=input[0];let mv=input[1]
    if nv<1 or nv>32 or mv<0 or mv>=nv:return -1
    let n=Int(nv);let m=Int(mv);let ep=2+2*m
    if Int(length)<=ep:return -1
    let qv=input[ep]
    if qv<0 or qv>128 or length!=c_size_t(ep+1+3*Int(qv)):return -1
    let q=Int(qv);var adj=List[Int](length=n,fill=0);var parent=List[Int](capacity=32)
    for i in range(n):parent.append(i)
    for i in range(m):
        let uu=input[2+2*i];let vv=input[3+2*i]
        if uu<0 or uu>=nv or vv<0 or vv>=nv or uu==vv:return -1
        let u=Int(uu);let v=Int(vv)
        if ((adj[u]>>v)&1)!=0:return -1
        let ru=dec_find(parent,u);let rv=dec_find(parent,v)
        if ru==rv:return -1
        parent[rv]=ru;adj[u]|=1<<v;adj[v]|=1<<u
    var comp=List[Int](length=n,fill=-1);var next=0
    for s in range(n):
        if comp[s]>=0:continue
        var stack=List[Int](capacity=1024);stack.append(s);comp[s]=next
        while len(stack)>0:
            let u=stack[len(stack)-1];stack.pop()
            for v in range(n):
                if ((adj[u]>>v)&1)!=0 and comp[v]<0:comp[v]=next;stack.append(v)
        next+=1
    var hash:UInt64=14695981039346656037
    for k in range(q):
        let p=ep+1+3*k;let op=input[p];let uu=input[p+1];let vv=input[p+2]
        if (op!=0 and op!=1) or uu<0 or uu>=nv or vv<0 or vv>=nv:return -1
        let u=Int(uu);let v=Int(vv)
        if op==1:
            if comp[u]==comp[v]:hash^=1
            hash*=1099511628211
        else:
            if ((adj[u]>>v)&1)==0 or comp[u]!=comp[v]:return -1
            adj[u]&= ~(1<<v);adj[v]&= ~(1<<u)
            var seen=List[Int](length=n,fill=0);var left=List[Int](capacity=32);var right=List[Int](capacity=32)
            let lc=dec_walk(adj,n,u,-1,-1,seen,left)
            for i in range(n):seen[i]=0
            let rc=dec_walk(adj,n,v,-1,-1,seen,right)
            if lc<rc or (lc==rc and u<v):
                for i in range(len(left)):comp[left[i]]=next
            else:
                for i in range(len(right)):comp[right[i]]=next
            next+=1
    return bitcast[Int64](hash)

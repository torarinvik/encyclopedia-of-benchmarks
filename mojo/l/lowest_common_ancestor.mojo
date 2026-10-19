from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAXN=1023

@export("lowest_common_ancestor")
fn lowest_common_ancestor(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>3073 or v[0]<2 or v[0]>MAXN:return -1
    let count=Int(v[0]);if n!=c_size_t(4+3*count):return -1
    let root=Int(v[1]);let p=Int(v[2]);let q=Int(v[3])
    if root<0 or root>=count or p<0 or p>=count or q<0 or q>=count or p==q:return -1
    var parent=InlineArray[Int64,MAXN](fill= -1);var values=InlineArray[Int64,MAXN](fill=0)
    for i in range(count):
        let off=4+3*i;let value=v[off]
        if value < -1000000000 or value>1000000000:return -1
        for prior in range(i):
            if values[prior]==value:return -1
        values[i]=value
        for side in range(2):
            let child=v[off+side+1]
            if child < -1 or child>=Int64(count):return -1
            if child>=0:
                if parent[Int(child)]!=-1:return -1
                parent[Int(child)]=Int64(i)
    if parent[root]!=-1:return -1
    for i in range(count):
        if i!=root and parent[i]==-1:return -1
    var seen=InlineArray[Int64,MAXN](fill=0);var stack=InlineArray[Int64,MAXN](fill=0);var top=1;var reached=0;stack[0]=Int64(root)
    while top>0:
        top-=1;let node=Int(stack[top]);if seen[node]!=0:return -1
        seen[node]=1;reached+=1;let off=4+3*node
        for side in range(2):
            let child=v[off+side+1]
            if child>=0:stack[top]=child;top+=1
    if reached!=count:return -1
    var pp=InlineArray[Int64,MAXN](fill=0);var pq=InlineArray[Int64,MAXN](fill=0);var dp=0;var dq=0;var cur=p
    while True:
        pp[dp]=Int64(cur);dp+=1
        if cur==root:break
        cur=Int(parent[cur])
    cur=q
    while True:
        pq[dq]=Int64(cur);dq+=1
        if cur==root:break
        cur=Int(parent[cur])
    var answer:Int64= -1
    while dp>0 and dq>0 and pp[dp-1]==pq[dq-1]:
        answer=pp[dp-1];dp-=1;dq-=1
    return answer

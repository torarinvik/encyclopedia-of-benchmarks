from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn dinic_dfs(u:Int,sink:Int,pushed:Int,mut residual:List[Int],level:List[Int],mut next:List[Int],n:Int)->Int:
    if u==sink:return pushed
    while next[u]<n:
        let v=next[u]
        if level[v]==level[u]+1 and residual[u*16+v]>0:
            let bound=residual[u*16+v] if residual[u*16+v]<pushed else pushed
            let sent=dinic_dfs(v,sink,bound,residual,level,next,n)
            if sent>0:residual[u*16+v]-=sent;residual[v*16+u]+=sent;return sent
        next[u]+=1
    return 0
@export("dinic_maxflow")
fn dinic_maxflow(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4:return -1
    let nv=input[0];let mv=input[1];let sv=input[2];let tv=input[3]
    if nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv or length!=c_size_t(4+3*mv):return -1
    let n=Int(nv);let m=Int(mv);let s=Int(sv-1);let t=Int(tv-1);var residual=List[Int](length=256,fill=0)
    for e in range(m):
        let u=input[4+3*e];let v=input[5+3*e];let c=input[6+3*e]
        if u<1 or u>nv or v<1 or v>nv or u==v or c<0 or c>100:return -1
        residual[Int(u-1)*16+Int(v-1)]+=Int(c)
    var flow:Int64=0
    while true:
        var level=List[Int](length=16,fill= -1);var queue=List[Int](capacity=16);level[s]=0;queue.append(s);var head=0
        while head<len(queue):
            let u=queue[head];head+=1
            for v in range(n):if residual[u*16+v]>0 and level[v]<0:level[v]=level[u]+1;queue.append(v)
        if level[t]<0:break
        var next=List[Int](length=16,fill=0)
        while true:
            let sent=dinic_dfs(s,t,6401,residual,level,next,n)
            if sent==0:break
            flow+=Int64(sent)
    return flow

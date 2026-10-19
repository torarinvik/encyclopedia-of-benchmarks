from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn dijkstra_pos_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt(8*b))&255)
@export("dijkstra_positive_connected")
fn dijkstra_positive_connected(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let nv=input[0];let mv=input[1]
    if nv<2 or nv>4 or mv<0 or mv>6 or length!=c_size_t(2+3*mv):return -1
    let n=Int(nv);let m=Int(mv)
    if m<n-1 or m>n*(n-1)/2:return -1
    var weights=List[Int](length=16,fill=0);var adj=List[Int](length=16,fill=0);var degree=List[Int](length=4,fill=0);var neighbors=List[Int](length=24,fill=0)
    for e in range(m):
        let uv=input[2+3*e];let vv=input[3+3*e];let ww=input[4+3*e]
        if uv<0 or uv>=nv or vv<0 or vv>=nv or uv==vv or ww<1 or ww>255:return -1
        let u=Int(uv);let v=Int(vv)
        if adj[u*4+v]!=0:return -1
        adj[u*4+v]=1;adj[v*4+u]=1;weights[u*4+v]=Int(ww);weights[v*4+u]=Int(ww)
        neighbors[u*6+degree[u]]=v;degree[u]+=1;neighbors[v*6+degree[v]]=u;degree[v]+=1
    var seen=List[Int](length=4,fill=0);var stack=List[Int](capacity=4);stack.append(0);seen[0]=1
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop()
        for i in range(degree[u]):let v=neighbors[u*6+i];if seen[v]==0:seen[v]=1;stack.append(v)
    for i in range(n):if seen[i]==0:return -1
    var dist=List[Int64](length=4,fill=9223372036854775807);var done=List[Int](length=4,fill=0);dist[0]=0
    for step in range(n):
        var u= -1
        for i in range(n):if done[i]==0 and (u<0 or dist[i]<dist[u]):u=i
        if u<0:break
        done[u]=1
        for j in range(degree[u]):
            let v=neighbors[u*6+j]
            if done[v]==0 and dist[u]+Int64(weights[u*4+v])<dist[v]:dist[v]=dist[u]+Int64(weights[u*4+v])
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n*8):return -2
    for i in range(n):dijkstra_pos_put(out,i,dist[i])
    return Int64(n*8)

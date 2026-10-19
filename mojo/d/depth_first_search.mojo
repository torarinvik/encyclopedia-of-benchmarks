from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
@export("depth_first_search")
fn depth_first_search(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>66 or (length-2)%2!=0:return -2
    if input[0]<0 or input[0]>64:return -2
    let n=Int(input[0]);let sv=input[1]
    if n==0:return 0 if sv== -1 and length==2 else -2
    if sv<0 or sv>=input[0]:return -2
    var adj=List[UInt64](length=n,fill=0)
    for e in range((Int(length)-2)/2):
        let u=input[2+2*e];let v=input[3+2*e]
        if u<0 or u>=input[0] or v<0 or v>=input[0]:return -2
        adj[Int(u)]|=UInt64(1)<<UInt(v)
    var visited=List[Int](length=n,fill=0);var order=List[Int](capacity=64);var vertices=List[Int](capacity=64);var nexts=List[Int](capacity=64)
    let start=Int(sv);visited[start]=1;order.append(start);vertices.append(start);nexts.append(0)
    while len(vertices)>0:
        let frame=len(vertices)-1;let u=vertices[frame]
        if nexts[frame]==n:vertices.pop();nexts.pop();continue
        let v=nexts[frame];nexts[frame]+=1
        if ((adj[u]>>UInt(v))&1)!=0 and visited[v]==0:
            visited[v]=1;order.append(v);vertices.append(v);nexts.append(0)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(order)):return -2
    for i in range(len(order)):out[i]=UInt8(order[i])
    return Int64(len(order))

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn dfs_rec_visit(adj:List[Int],degree:List[Int],u:Int,target:Int64,mut visited:List[Int])->Bool:
    if Int64(u)==target:return true
    visited[u]=1
    for i in range(degree[u]):
        let v=adj[u*64+i]
        if visited[v]==0 and dfs_rec_visit(adj,degree,v,target,visited):return true
    return false
@export("depth_first_search_recursive")
fn depth_first_search_recursive(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>518:return -1
    let nv=input[0];let me=input[1];let sv=input[2];let target=input[3]
    if nv<1 or nv>64 or me<0 or me>256 or sv<0 or sv>=nv or length!=c_size_t(4+2*me):return -1
    for e in range(Int(me)):
        if input[4+2*e]<0 or input[4+2*e]>=nv or input[5+2*e]<0 or input[5+2*e]>=nv:return -1
    var adj=List[Int](length=64*64,fill=0);var degree=List[Int](length=64,fill=0);var seen=List[UInt64](length=64,fill=0)
    for e in range(Int(me)):
        let l=Int(input[4+2*e]);let r=Int(input[5+2*e]);let rb=UInt64(1)<<UInt(r)
        if (seen[l]&rb)==0:seen[l]|=rb;adj[l*64+degree[l]]=r;degree[l]+=1
        let lb=UInt64(1)<<UInt(l)
        if (seen[r]&lb)==0:seen[r]|=lb;adj[r*64+degree[r]]=l;degree[r]+=1
    var visited=List[Int](length=64,fill=0)
    return 1 if dfs_rec_visit(adj,degree,Int(sv),target,visited) else 0

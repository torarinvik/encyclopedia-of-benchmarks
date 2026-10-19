from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn cycles_dfs(current:Int,start:Int,n:Int,mut adj:List[Int],mut path:List[Int],mut visited:List[Int],mut output:List[UInt8]):
    for neighbor in range(n):
        if adj[current*n+neighbor]==0:continue
        if neighbor==start:
            for i in range(len(path)):output.append(UInt8(path[i]))
            output.append(UInt8(start));output.append(UInt8(255))
        elif visited[neighbor]==0:
            visited[neighbor]=1;path.append(neighbor);cycles_dfs(neighbor,start,n,adj,path,visited,output);path.pop();visited[neighbor]=0
@export("directed_simple_cycles")
fn directed_simple_cycles(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or input[0]<0 or input[0]>6 or input[1]<0 or input[1]>36:return -1
    let n=Int(input[0]);let m=Int(input[1])
    if length!=c_size_t(2+2*m):return -1
    var adj=List[Int](length=36,fill=0)
    for e in range(m):
        let u=input[2+2*e];let v=input[3+2*e]
        if u<0 or u>=Int64(n) or v<0 or v>=Int64(n):return -1
        adj[Int(u)*n+Int(v)]=1
    var staged=List[UInt8](capacity=2786)
    for start in range(n):
        var path=List[Int](capacity=6);var visited=List[Int](length=6,fill=0);path.append(start);visited[start]=1
        cycles_dfs(start,start,n,adj,path,visited,staged)
        for v in range(n):adj[start*n+v]=0;adj[v*n+start]=0
    if len(staged)==0:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(staged)):return -2
    for i in range(len(staged)):out[i]=staged[i]
    return Int64(len(staged))

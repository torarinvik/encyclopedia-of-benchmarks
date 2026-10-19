from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn euler_undirected_dfs(u:Int,n:Int,m:Int,adj:List[List[Int]],mut seen:InlineArray[Int64,100],mut path:List[Int64]):
    path.append(Int64(u))
    for i in range(len(adj[u])):
        let v=adj[u][i]
        if seen[u*10+v]==0:
            seen[u*10+v]=1;seen[v*10+u]=1;euler_undirected_dfs(v,n,m,adj,seen,path)
fn euler_undirected_put(out:UnsafePointer[UInt8,MutAnyOrigin],index:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[index*8+b]=UInt8((bits>>UInt(8*b))&255)
@export("eulerian_trail_undirected_simple")
fn eulerian_trail_undirected_simple(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let nn=input[0];let mm=input[1]
    if nn<2 or nn>10 or mm<0 or mm>45 or length!=c_size_t(2+2*mm):return -1
    let n=Int(nn);let m=Int(mm);var adj=List[List[Int]](capacity=n);for i in range(n):adj.append(List[Int](capacity=m))
    var edge_seen=InlineArray[Int64,100](fill=0);var degree=List[Int](length=n,fill=0)
    for i in range(m):
        let u=input[2+2*i];let v=input[3+2*i]
        if u<0 or u>=nn or v<0 or v>=nn or u==v:return -1
        if edge_seen[Int(u)*10+Int(v)]!=0:return -1
        edge_seen[Int(u)*10+Int(v)]=1;edge_seen[Int(v)*10+Int(u)]=1
        adj[Int(u)].append(Int(v));adj[Int(v)].append(Int(u));degree[Int(u)]+=1;degree[Int(v)]+=1
    var odd=0;var start=1
    for v in range(n):if degree[v]%2==1:odd+=1;start=v
    if odd!=0 and odd!=2:return -1
    let status=2 if odd==2 else 1
    if status==1:start=1
    if m>0:
        if status==1 and degree[1]==0:return -1
        var reached=InlineArray[Int64,10](fill=0);var stack=List[Int](capacity=n);stack.append(start);reached[start]=1
        while len(stack)>0:
            let u=stack[len(stack)-1];stack.pop()
            for i in range(len(adj[u])):
                let v=adj[u][i]
                if reached[v]==0:reached[v]=1;stack.append(v)
        for v in range(n):if degree[v]>0 and reached[v]==0:return -1
    var seen=InlineArray[Int64,100](fill=0);var path=List[Int64](capacity=m+1)
    euler_undirected_dfs(start,n,m,adj,seen,path)
    if len(path)!=m+1:return -1
    let bytes=(2+len(path))*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    euler_undirected_put(out,0,status);euler_undirected_put(out,1,Int64(len(path)))
    for i in range(len(path)):euler_undirected_put(out,2+i,path[i])
    return Int64(bytes)

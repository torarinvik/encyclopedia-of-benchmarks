from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn euler_path_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("eulerian_path")
fn eulerian_path(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>514:return -1
    let nn=input[0];let mm=input[1]
    if nn<0 or nn>32 or mm<0 or mm>256 or length!=c_size_t(2+2*mm):return -1
    let n=Int(nn);let m=Int(mm);var adj=List[List[Int64]](capacity=n);var indeg=List[Int](length=n,fill=0);var outdeg=List[Int](length=n,fill=0)
    for v in range(n):adj.append(List[Int64](capacity=m))
    for i in range(m):
        let u=input[2+2*i];let v=input[3+2*i]
        if u<0 or u>=nn or v<0 or v>=nn:return -1
        adj[Int(u)].append(v);outdeg[Int(u)]+=1;indeg[Int(v)]+=1
    if m==0:return 0
    var start= -1;var plus=0;var minus=0
    for v in range(n):
        let diff=outdeg[v]-indeg[v]
        if diff==1:plus+=1;start=v
        elif diff== -1:minus+=1
        elif diff!=0:return -1
    if not ((plus==0 and minus==0) or (plus==1 and minus==1)):return -1
    if plus==0:
        start=0
        while start<n and outdeg[start]==0:start+=1
    var stack=List[Int64](capacity=m+1);var path=List[Int64](capacity=m+1);stack.append(Int64(start))
    while len(stack)>0:
        let v=Int(stack[len(stack)-1])
        if len(adj[v])>0:
            let next=adj[v][len(adj[v])-1];adj[v].pop();stack.append(next)
        else:path.append(stack[len(stack)-1]);stack.pop()
    if len(path)!=m+1:return -1
    let bytes=(m+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(m+1):euler_path_put(out,8*i,path[m-i])
    return Int64(bytes)

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn dfs_order_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt(8*b))&255)
@export("depth_first_search_iterative_order")
fn depth_first_search_iterative_order(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3:return -1
    let nv=input[0];let ev=input[1]
    if nv<1 or nv>10 or ev<0 or ev>64 or length!=c_size_t(3+2*ev):return -1
    let n=Int(nv);var adj=List[Int](length=11*128,fill=0);var degree=List[Int](length=11,fill=0)
    for e in range(Int(ev)):
        let lv=input[2+2*e];let rv=input[3+2*e]
        if lv<1 or lv>nv or rv<1 or rv>nv:return -1
        let l=Int(lv);let r=Int(rv)
        adj[l*128+degree[l]]=r;degree[l]+=1;adj[r*128+degree[r]]=l;degree[r]+=1
    let sv=input[Int(length)-1]
    if sv<1 or sv>nv:return -1
    var visited=List[Int](length=11,fill=0);var stack=List[Int](capacity=10);var order=List[Int](capacity=10)
    visited[Int(sv)]=1;stack.append(Int(sv))
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop();order.append(u)
        for e in range(degree[u]):
            let v=adj[u*128+e]
            if visited[v]==0:visited[v]=1;stack.append(v)
    let bytes=(len(order)+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    dfs_order_put(out,0,Int64(len(order)))
    for i in range(len(order)):dfs_order_put(out,i+1,Int64(order[i]))
    return Int64(bytes)

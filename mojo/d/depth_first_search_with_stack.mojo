from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
@export("depth_first_search_with_stack")
fn depth_first_search_with_stack(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>66 or (length-2)%2!=0:return -2
    if input[0]<0 or input[0]>64:return -2
    let nv=input[0];let startv=input[1]
    if nv==0:return 0 if startv== -1 and length==2 else -2
    if startv<0 or startv>=nv:return -2
    let n=Int(nv);let edges=(Int(length)-2)/2
    var adj=List[Int](length=64*32,fill=0);var degree=List[Int](length=64,fill=0);var state=List[Int](length=64,fill=0)
    for e in range(edges):
        let u=input[2+2*e];let v=input[3+2*e]
        if u<0 or u>=nv or v<0 or v>=nv:return -2
        adj[Int(u)*32+degree[Int(u)]]=Int(v);degree[Int(u)]+=1
    var stack=List[Int](capacity=33);var order=List[Int](capacity=64);let start=Int(startv);state[start]=1;stack.append(start)
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop()
        if state[u]!=1:continue
        order.append(u)
        for e in range(degree[u]):
            let v=adj[u*32+e];stack.append(v)
            if state[v]!=2:state[v]=1
        state[u]=2
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(order)):return -2
    for i in range(len(order)):out[i]=UInt8(order[i])
    return Int64(len(order))

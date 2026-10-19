from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
@export("depth_first_search_target_route")
fn depth_first_search_target_route(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5 or length>256:return -2
    let nv=input[0];let start_label=input[1];let target=input[2]
    if nv<1 or nv>64 or start_label<0 or start_label>255 or target<0 or target>255:return -2
    let n=Int(nv);let ep=3+n
    if Int(length)<=ep:return -2
    var labels=List[Int](capacity=64);var start= -1
    for i in range(n):
        let v=input[3+i]
        if v<0 or v>255:return -2
        for j in range(i):
            if labels[j]==Int(v):return -2
        labels.append(Int(v));if v==start_label:start=i
    if start<0:return -2
    let ev=input[ep]
    if ev<0 or ev>94 or length!=c_size_t(ep+1+2*ev):return -2
    var adj=List[UInt64](length=n,fill=0)
    for e in range(Int(ev)):
        let lv=input[ep+1+2*e];let rv=input[ep+2+2*e];var l= -1;var r= -1
        for i in range(n):
            if labels[i]==Int(lv):l=i
            if labels[i]==Int(rv):r=i
        if l<0 or r<0:return -2
        adj[l]|=UInt64(1)<<UInt(r);adj[r]|=UInt64(1)<<UInt(l)
    var stack=List[Int](capacity=64);stack.append(start);var route=List[Int](capacity=128)
    while len(stack)>0:
        let current=stack[len(stack)-1];stack.pop()
        if len(route)>=128:return -2
        route.append(labels[current])
        for neighbor in range(n):
            let bit=UInt64(1)<<UInt(neighbor)
            if (adj[current]&bit)!=0:
                var pending=false
                for p in range(len(stack)):
                    if stack[p]==neighbor:pending=true
                if not pending:stack.append(neighbor)
            adj[current]&=~bit;adj[neighbor]&=~(UInt64(1)<<UInt(current))
        if labels[current]==Int(target):
            if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(route)):return -2
            for i in range(len(route)):out[i]=UInt8(route[i])
            return Int64(len(route))
    return 0

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("edmonds_karp")
fn edmonds_karp(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4:return -1
    let n64=input[0];let source=input[1];let sink=input[2]
    if n64<1 or n64>16 or source<0 or source>=n64 or sink<0 or sink>=n64 or length!=c_size_t(3+n64*n64):return -1
    let n=Int(n64);var residual=List[Int64](capacity=n*n)
    for i in range(n*n):
        let c=input[3+i]
        if c<0 or c>1000000:return -1
        residual.append(c)
    for i in range(n):
        if residual[i*n+i]!=0:return -1
        for j in range(i+1,n):
            if residual[i*n+j]>0 and residual[j*n+i]>0:return -1
    if source==sink:return 0
    var total:Int64=0
    while True:
        var parent=List[Int](length=n,fill= -1);parent[Int(source)]=Int(source)
        var queue=List[Int](capacity=n);queue.append(Int(source));var head=0
        while head<len(queue) and parent[Int(sink)]== -1:
            let u=queue[head];head+=1
            for v in range(n):
                if parent[v]== -1 and residual[u*n+v]>0:parent[v]=u;queue.append(v)
        if parent[Int(sink)]== -1:break
        var flow:Int64=1000001;var v=Int(sink)
        while v!=Int(source):let u=parent[v];if residual[u*n+v]<flow:flow=residual[u*n+v];v=u
        v=Int(sink)
        while v!=Int(source):let u=parent[v];residual[u*n+v]-=flow;residual[v*n+u]+=flow;v=u
        total+=flow
    return total

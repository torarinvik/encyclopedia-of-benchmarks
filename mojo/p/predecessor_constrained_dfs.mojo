from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pc_visit(node:Int,count:Int,adj:InlineArray[Bool,256],pred:InlineArray[Bool,256],inout seen:InlineArray[Bool,16],inout ev:InlineArray[Int64,408],inout ec:Int,inout order:Int):
    seen[node]=True;ev[ec*3]=1;ev[ec*3+1]=Int64(node);ev[ec*3+2]=Int64(order);ec+=1;order+=1
    for child in range(count):
        if not adj[node*16+child] or seen[child]:continue
        var ready=True
        for parent in range(count):
            if pred[child*16+parent] and not seen[parent]:ready=False
        if ready:pc_visit(child,count,adj,pred,seen,ev,ec,order)
        else:ev[ec*3]=0;ev[ec*3+1]=Int64(child);ev[ec*3+2]= -1;ec+=1
@export("predecessor_constrained_dfs")
fn predecessor_constrained_dfs(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258 or v[0]<1 or v[0]>16 or v[1]<0 or v[1]>=v[0] or n!=c_size_t(2+v[0]*v[0]):return -1
    let count=Int(v[0]);var adj=InlineArray[Bool,256](fill=False);var pred=InlineArray[Bool,256](fill=False);var indeg=InlineArray[Int,16](fill=0)
    for i in range(count):for j in range(count):
        let bit=v[2+i*count+j]
        if (bit!=0 and bit!=1) or (i==j and bit!=0):return -1
        if bit==1:adj[i*16+j]=True;pred[j*16+i]=True;indeg[j]+=1
    var queue=InlineArray[Int,16](fill=0);var head=0;var tail=0
    for i in range(count):if indeg[i]==0:queue[tail]=i;tail+=1
    while head<tail:
        let node=queue[head];head+=1
        for child in range(count):
            if adj[node*16+child]:indeg[child]-=1;if indeg[child]==0:queue[tail]=child;tail+=1
    if tail!=count:return -1
    var seen=InlineArray[Bool,16](fill=False);var events=InlineArray[Int64,408](fill=0);var ec=0;var order=0
    pc_visit(Int(v[1]),count,adj,pred,seen,events,ec,order)
    let bytes=ec*12
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(ec):for j in range(3):
        let bits=UInt32(events[i*3+j])
        for b in range(4):out[i*12+j*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)

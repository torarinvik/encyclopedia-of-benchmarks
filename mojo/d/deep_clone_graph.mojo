from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn clone_mix(h0:UInt64,x0:UInt64)->UInt64:
    var h=h0;var x=x0
    for b in range(8):h^=UInt64(x&255);h*=1099511628211;x>>=8
    return h
@export("deep_clone_graph")
fn deep_clone_graph(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>34:return -1
    let nn=input[0];let rootv=input[1]
    if nn<1 or nn>16 or rootv<0 or rootv>=nn or length!=c_size_t(2+2*nn):return -1
    let n=Int(nn);let root=Int(rootv);var masks=List[UInt64](length=n,fill=0);var vals=List[Int64](capacity=16)
    let limit=(UInt64(1)<<UInt(n))-1
    for i in range(n):
        let v=input[2+i];let m=input[2+n+i]
        if v< -2147483648 or v>2147483647 or m<0 or UInt64(m)>limit:return -1
        vals.append(v);masks[i]=UInt64(m)
    for i in range(n):
        for j in range(n):
            if ((masks[i]>>UInt(j))&1)!=((masks[j]>>UInt(i))&1):return -1
    var seen=List[Int](length=n,fill=0);var stack=List[Int](capacity=256);stack.append(root);var count=0
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop()
        if seen[u]!=0:continue
        seen[u]=1;count+=1
        for v in range(n):
            if ((masks[u]>>UInt(v))&1)!=0 and seen[v]==0:stack.append(v)
    var h:UInt64=14695981039346656037
    h=clone_mix(h,UInt64(count));h=clone_mix(h,UInt64(root))
    for i in range(n):
        if seen[i]!=0:h=clone_mix(h,bitcast[UInt64](vals[i]));h=clone_mix(h,masks[i])
    return bitcast[Int64](h)

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pc_write(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("prufer_code")
fn prufer_code(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>129:return -1
    let mode=input[0];let n64=input[1]
    if n64<1 or n64>64 or (mode!=0 and mode!=1):return -1
    let n=Int(n64)
    if mode==0:
        if length!=c_size_t(2*n):return -1
        var adj=InlineArray[Bool,4096](fill=False);var degree=InlineArray[Int32,64](fill=0)
        for edge in range(n-1):
            let u=input[2+edge*2];let v=input[3+edge*2]
            if u<0 or v<0 or u>=n64 or v>=n64 or u==v:return -1
            if adj[Int(u)*64+Int(v)]:return -1
            adj[Int(u)*64+Int(v)]=True;adj[Int(v)*64+Int(u)]=True;degree[Int(u)]+=1;degree[Int(v)]+=1
        var seen=InlineArray[Bool,64](fill=False);var queue=InlineArray[Int32,64](fill=0);var head=0;var tail=1;seen[0]=True
        while head<tail:
            let u=Int(queue[head]);head+=1
            for v in range(n):
                if adj[u*64+v] and !seen[v]:seen[v]=True;queue[tail]=Int32(v);tail+=1
        if tail!=n:return -1
        var active=InlineArray[Bool,64](fill=True);var code=InlineArray[Int64,64](fill=0);let codelen=0 if n<2 else n-2
        for step in range(codelen):
            var leaf= -1
            for v in range(n-1,-1,-1):
                if active[v] and degree[v]==1:leaf=v;break
            if leaf<0:return -1
            var neighbor= -1
            for v in range(n):
                if active[v] and adj[leaf*64+v]:neighbor=v;break
            if neighbor<0:return -1
            code[step]=Int64(neighbor);active[leaf]=False;adj[leaf*64+neighbor]=False;adj[neighbor*64+leaf]=False;degree[neighbor]-=1
        let needed=codelen*8
        if needed==0:return 0
        if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
        for i in range(codelen):pc_write(output,i*8,code[i])
        return Int64(needed)
    if n<2 or length!=c_size_t(n):return -1
    var remaining=InlineArray[Int32,64](fill=0)
    for i in range(n-2):
        let raw=input[2+i]
        if raw<0 or raw>=n64:return -1
        remaining[Int(raw)]+=1
    var active=InlineArray[Bool,64](fill=True);var eu=InlineArray[Int32,63](fill=0);var ev=InlineArray[Int32,63](fill=0);var out=0
    for i in range(n-2):
        var leaf= -1
        for v in range(n-1,-1,-1):
            if active[v] and remaining[v]==0:leaf=v;break
        if leaf<0:return -1
        let vertex=Int(input[2+i]);let u=leaf if leaf<vertex else vertex;let v=vertex if leaf<vertex else leaf
        eu[out]=Int32(u);ev[out]=Int32(v);out+=1;active[leaf]=False;remaining[vertex]-=1
    var first= -1
    for v in range(n-1,-1,-1):if active[v]:first=v;break
    if first<0:return -1
    active[first]=False;var second= -1
    for v in range(n-1,-1,-1):if active[v]:second=v;break
    if second<0:return -1
    eu[out]=Int32(first if first<second else second);ev[out]=Int32(second if first<second else first);out+=1
    for i in range(1,out):
        let u=eu[i];let v=ev[i];var j=i
        while j>0 and (eu[j-1]>u or (eu[j-1]==u and ev[j-1]>v)):eu[j]=eu[j-1];ev[j]=ev[j-1];j-=1
        eu[j]=u;ev[j]=v
    let needed=8+out*16
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    pc_write(output,0,Int64(out))
    for i in range(out):pc_write(output,8+i*16,Int64(eu[i]));pc_write(output,16+i*16,Int64(ev[i]))
    return Int64(needed)

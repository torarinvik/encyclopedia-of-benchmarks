from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gh_flow(cap:InlineArray[Int64,64],n:Int,s:Int,t:Int,mut reach:InlineArray[Bool,8])->Int64:
    var residual=InlineArray[Int64,64](fill=0)
    for i in range(n*n):residual[i]=cap[i]
    var total:Int64=0
    while True:
        var parent=InlineArray[Int,8](fill= -1);var queue=InlineArray[Int,8](fill=0);parent[s]=s;var head=0;var tail=0;queue[tail]=s;tail+=1
        while head<tail and parent[t]<0:
            let u=queue[head];head+=1
            for v in range(n):
                if residual[u*n+v]>0 and parent[v]<0:
                    parent[v]=u
                    if v==t:break
                    queue[tail]=v;tail+=1
        if parent[t]<0:break
        var amount:Int64=9223372036854775807;var v=t
        while v!=s:
            if residual[parent[v]*n+v]<amount:amount=residual[parent[v]*n+v]
            v=parent[v]
        v=t
        while v!=s:
            let u=parent[v];residual[u*n+v]-=amount;residual[v*n+u]+=amount;v=u
        total+=amount
    for i in range(n):reach[i]=False
    var q=InlineArray[Int,8](fill=0);var head2=0;var tail2=0;q[tail2]=s;tail2+=1;reach[s]=True
    while head2<tail2:
        let u=q[head2];head2+=1
        for v in range(n):
            if not reach[v] and residual[u*n+v]>0:reach[v]=True;q[tail2]=v;tail2+=1
    return total
fn gh_hashbyte(h0:UInt64,b:UInt64)->UInt64:return (h0^b)*UInt64(1099511628211)
@export("gomory_hu_tree")
fn gomory_hu_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>65 or v[0]<1 or v[0]>8:return -1
    let n=Int(v[0]);if length!=c_size_t(1+n*n):return -1
    var cap=InlineArray[Int64,64](fill=0)
    for i in range(n*n):if v[i+1]<0 or v[i+1]>1000:return -1;cap[i]=v[i+1]
    for i in range(n):
        for j in range(n):if cap[i*n+j]!=(0 if i==j else cap[j*n+i]):return -1
    var parent=InlineArray[Int,8](fill=0);var weight=InlineArray[Int64,8](fill=0);parent[0]= -1
    for s in range(1,n):
        let t=parent[s];var reach=InlineArray[Bool,8](fill=False);let flow=gh_flow(cap,n,s,t,reach);weight[s]=flow
        for x in range(n):if x!=s and parent[x]==t and reach[x]:parent[x]=s
        if t!=0 and reach[parent[t]]:
            parent[s]=parent[t];parent[t]=s;weight[s]=weight[t];weight[t]=flow
    var pair=InlineArray[Int64,64](fill=0)
    for source in range(n):
        var q=InlineArray[Int,8](fill=0);var prev=InlineArray[Int,8](fill= -2);var head=0;var tail=0;q[tail]=source;tail+=1;prev[source]= -1
        while head<tail:
            let u=q[head];head+=1
            for x in range(n):
                var edge= -1
                if x!=u and parent[x]==u:edge=x
                elif x!=u and parent[u]==x:edge=u
                if edge>=0 and prev[x]== -2:prev[x]=u;q[tail]=x;tail+=1
        for target in range(n):
            if target!=source:
                var x=target;var minimum:Int64=9223372036854775807
                while x!=source:
                    let p=prev[x];let edge=if parent[x]==p then x else p
                    if weight[edge]<minimum:minimum=weight[edge]
                    x=p
                pair[source*n+target]=minimum
    var hash=UInt64(14695981039346656037)
    for i in range(n*n):
        let bits=bitcast[UInt64](pair[i])
        for b in range(8):hash=gh_hashbyte(hash,(bits>>UInt64(8*b))&255)
    return bitcast[Int64](hash)

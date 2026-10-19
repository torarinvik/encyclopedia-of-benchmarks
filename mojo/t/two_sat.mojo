from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime TS_LITS=80
@export("two_sat")
fn two_sat(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4096:return -1
    let vars=a[0];let clauses=a[1]
    if vars<0 or vars>40 or clauses<0 or clauses>2047 or n!=c_size_t(2+2*clauses):return -1
    let nodes=Int(vars)*2
    var graph=InlineArray[Bool,6400]();var trans=InlineArray[Bool,6400]()
    for ci in range(Int(clauses)):
        let aa=a[2+2*ci];let bb=a[3+2*ci]
        if aa==0 or bb==0 or aa< -vars or aa>vars or bb< -vars or bb>vars:return -1
        let x=2*(Int(abs(aa))-1)+(1 if aa<0 else 0);let y=2*(Int(abs(bb))-1)+(1 if bb<0 else 0)
        let u1=x^1;let v1=y;let u2=y^1;let v2=x
        graph[u1*TS_LITS+v1]=True;trans[v1*TS_LITS+u1]=True
        graph[u2*TS_LITS+v2]=True;trans[v2*TS_LITS+u2]=True
    var seen=InlineArray[Bool,80]();var order=InlineArray[Int32,80]();var olen=0
    var stack=InlineArray[Int32,80]();var next=InlineArray[Int32,80]()
    for root in range(nodes):
        if seen[root]:continue
        var top=0;stack[0]=Int32(root);next[0]=0;seen[root]=True
        while top>=0:
            let v=Int(stack[top]);var w=Int(next[top]);var advanced=false
            while w<nodes:
                next[top]=Int32(w+1)
                if graph[v*TS_LITS+w] and not seen[w]:
                    seen[w]=True;top+=1;stack[top]=Int32(w);next[top]=0;advanced=true;break
                w+=1
            if not advanced:
                order[olen]=Int32(v);olen+=1;top-=1
    var comp=InlineArray[Int32,80]();for i in range(80):comp[i]= -1
    var cid=0
    while olen>0:
        olen-=1;let root=Int(order[olen])
        if comp[root]>=0:continue
        var top=0;stack[0]=Int32(root);comp[root]=Int32(cid)
        while top>=0:
            let v=Int(stack[top]);top-=1
            for w in range(nodes):
                if trans[v*TS_LITS+w] and comp[w]<0:
                    comp[w]=Int32(cid);top+=1;stack[top]=Int32(w)
        cid+=1
    var satisfiable=true
    for i in range(Int(vars)):if comp[2*i]==comp[2*i+1]:satisfiable=false
    let outlen=Int(vars)+1 if satisfiable else 1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    o[0]=1 if satisfiable else 0
    if satisfiable:
        for i in range(Int(vars)):o[i+1]=1 if comp[2*i]>comp[2*i+1] else 0
    return Int64(outlen)

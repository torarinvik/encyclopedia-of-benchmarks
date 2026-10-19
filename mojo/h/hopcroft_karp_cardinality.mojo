from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hkc_dfs(u:Int,nr:Int,inout adj:InlineArray[Bool,4096],inout lm:InlineArray[Int,64],inout rm:InlineArray[Int,64],inout dist:InlineArray[Int,64])->Bool:
    for v in range(nr):
        if not adj[u*64+v]:continue
        let mate=rm[v]
        if mate<0 or (dist[mate]==dist[u]+1 and hkc_dfs(mate,nr,adj,lm,rm,dist)):
            lm[u]=v;rm[v]=u;return true
    dist[u]=1000000;return false
@export("hopcroft_karp_cardinality")
fn hopcroft_karp_cardinality(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let nl=a[0];let nr=a[1];let ec=a[2]
    if nl<0 or nl>64 or nr<0 or nr>64 or ec<0 or ec>4096 or n!=c_size_t(3+2*ec):return -1
    var adj=InlineArray[Bool,4096](fill=false)
    for i in range(Int(ec)):
        let l=a[3+2*i];let r=a[4+2*i]
        if l<0 or l>=nl or r<0 or r>=nr:return -1
        adj[Int(l)*64+Int(r)]=true
    var lm=InlineArray[Int,64](fill=-1);var rm=InlineArray[Int,64](fill=-1);var dist=InlineArray[Int,64](fill=0);var matching=0
    while true:
        var queue=InlineArray[Int,64](fill=0);var head=0;var tail=0;var found=false
        for u in range(Int(nl)):
            if lm[u]<0:dist[u]=0;queue[tail]=u;tail+=1
            else:dist[u]=1000000
        while head<tail:
            let u=queue[head];head+=1
            for v in range(Int(nr)):
                if not adj[u*64+v]:continue
                let mate=rm[v]
                if mate<0:found=true
                elif dist[mate]==1000000:dist[mate]=dist[u]+1;queue[tail]=mate;tail+=1
        if not found:break
        var changed=0
        for u in range(Int(nl)):if lm[u]<0 and hkc_dfs(u,Int(nr),adj,lm,rm,dist):matching+=1;changed+=1
        if changed==0:break
    return Int64(matching)

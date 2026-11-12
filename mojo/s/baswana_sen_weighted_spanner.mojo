from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn bsw_before(aw:Int64,au:Int64,av:Int64,bw:Int64,bu:Int64,bv:Int64)->Bool:
    return aw<bw or (aw==bw and au<bu) or (aw==bw and au==bu and av<bv)

@export("baswana_sen_weighted_spanner")
fn baswana_sen_weighted_spanner(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>90:return -1
    let n64=input[0];let m64=input[1];let k=input[2]
    if n64<2 or n64>8 or m64<0 or m64>28 or k<2 or k>3:return -1
    let n=Int(n64);let m=Int(m64);let rounds=Int(k-1)
    if length!=c_size_t(3+rounds+3*m):return -1
    var masks=InlineArray[Int64,8](fill=0)
    for r in range(rounds):
        masks[r]=input[3+r]
        if masks[r]<0 or masks[r]>=(Int64(1)<<n):return -1
    var edge_u=InlineArray[Int64,28](fill=0);var edge_v=InlineArray[Int64,28](fill=0);var edge_w=InlineArray[Int64,28](fill=0)
    var active=InlineArray[Bool,28](fill=False);var selected=InlineArray[UInt8,28](fill=0)
    let offset=3+rounds
    for e in range(m):
        edge_u[e]=input[offset+3*e];edge_v[e]=input[offset+3*e+1];edge_w[e]=input[offset+3*e+2]
        if edge_u[e]<0 or edge_v[e]<=edge_u[e] or edge_v[e]>=n64 or edge_w[e]<1 or edge_w[e]>32:return -1
        for p in range(e):
            if edge_u[p]==edge_u[e] and edge_v[p]==edge_v[e]:return -1
        active[e]=True
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(m):return -2
    var cluster=InlineArray[Int,8](fill=0);var next_cluster=InlineArray[Int,8](fill=-1)
    for v in range(n):cluster[v]=v
    for r in range(rounds):
        var sampled=InlineArray[Bool,8](fill=False);var remove=InlineArray[Bool,28](fill=False)
        var group_best=InlineArray[Int,64](fill=m)
        for v in range(n):next_cluster[v]=-1
        for v in range(n):
            let center=cluster[v]
            if center>=0 and ((masks[r]>>center)&1)!=0:sampled[center]=True
        for v in range(n):
            if cluster[v]>=0 and sampled[cluster[v]]:next_cluster[v]=cluster[v]
        for e in range(m):
            if not active[e]:continue
            let u=Int(edge_u[e]);let v=Int(edge_v[e])
            if cluster[v]>=0:
                let slot=u*8+cluster[v];let prior=group_best[slot]
                if prior==m or bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]):group_best[slot]=e
            if cluster[u]>=0:
                let slot=v*8+cluster[u];let prior=group_best[slot]
                if prior==m or bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]):group_best[slot]=e
        for v in range(n):
            let old=cluster[v]
            if old<0 or sampled[old]:continue
            var best=m
            for c in range(n):
                let candidate=group_best[v*8+c]
                if sampled[c] and candidate!=m and (best==m or bsw_before(edge_w[candidate],edge_u[candidate],edge_v[candidate],edge_w[best],edge_u[best],edge_v[best])):best=candidate
            if best==m:
                for c in range(n):
                    let least=group_best[v*8+c]
                    if least==m:continue
                    selected[least]=1
                    for e in range(m):
                        if not active[e]:continue
                        let a=Int(edge_u[e]);let b=Int(edge_v[e])
                        if (a==v and cluster[b]==c) or (b==v and cluster[a]==c):remove[e]=True
                continue
            let a=Int(edge_u[best]);let b=Int(edge_v[best])
            var other=a
            if a==v:other=b
            let landing=cluster[other]
            next_cluster[v]=landing;selected[best]=1
            for c in range(n):
                let least=group_best[v*8+c]
                if least==m:continue
                let erase_group=(c==landing or edge_w[least]<edge_w[best])
                if c!=landing and edge_w[least]<edge_w[best]:selected[least]=1
                if erase_group:
                    for e in range(m):
                        if not active[e]:continue
                        let x=Int(edge_u[e]);let y=Int(edge_v[e])
                        if (x==v and cluster[y]==c) or (y==v and cluster[x]==c):remove[e]=True
        for e in range(m):
            if remove[e]:active[e]=False
        for e in range(m):
            if active[e]:
                let u=Int(edge_u[e]);let v=Int(edge_v[e])
                if next_cluster[u]>=0 and next_cluster[u]==next_cluster[v]:active[e]=False
        for v in range(n):cluster[v]=next_cluster[v]
    var group_best=InlineArray[Int,64](fill=m)
    for e in range(m):
        if not active[e]:continue
        let u=Int(edge_u[e]);let v=Int(edge_v[e])
        if cluster[v]>=0:
            let slot=u*8+cluster[v];let prior=group_best[slot]
            if prior==m or bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]):group_best[slot]=e
        if cluster[u]>=0:
            let slot=v*8+cluster[u];let prior=group_best[slot]
            if prior==m or bsw_before(edge_w[e],edge_u[e],edge_v[e],edge_w[prior],edge_u[prior],edge_v[prior]):group_best[slot]=e
    for v in range(n):
        if cluster[v]>=0:
            for c in range(n):
                let least=group_best[v*8+c]
                if least!=m:selected[least]=1
    for e in range(m):output[e]=selected[e]
    return Int64(m)

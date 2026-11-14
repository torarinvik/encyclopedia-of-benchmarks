# Bounded additive phylogeny reconstruction; see package README for provenance.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn phylo_paths(nodes: Int, count: Int, eu: InlineArray[Int,9], ev: InlineArray[Int,9],
               ew: InlineArray[Int64,9], start: Int, mut parent: InlineArray[Int,10],
               mut parent_edge: InlineArray[Int,10], mut distance: InlineArray[Int64,10]):
    for i in range(nodes): parent[i] = -1; parent_edge[i] = -1; distance[i]=0
    var queue=InlineArray[Int,10](fill=0)
    var head=0; var tail=1
    queue[0]=start; parent[start]=start
    while head<tail:
        let node=queue[head]; head+=1
        for e in range(count):
            var other = -1
            if eu[e]==node: other=ev[e]
            elif ev[e]==node: other=eu[e]
            if other<0 or parent[other]>=0: continue
            parent[other]=node; parent_edge[other]=e
            distance[other]=distance[node]+ew[e]
            queue[tail]=other; tail+=1

@export("phylogenetic_tree_from_distance_matrix")
fn phylogenetic_tree_from_distance_matrix(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>38: return -1
    if input[0]<2 or input[0]>6: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+n*n): return -1
    var matrix=InlineArray[Int64,36](fill=0)
    for i in range(n):
        for j in range(n):
            let value=input[1+i*n+j]
            if (i==j and value!=0) or (i!=j and (value<1 or value>32)): return -1
            matrix[i*6+j]=value
    for i in range(n):
        for j in range(i+1,n):
            if matrix[6*i+j]!=matrix[6*j+i]: return -1
    var eu=InlineArray[Int,9](fill=0); var ev=InlineArray[Int,9](fill=0)
    var ew=InlineArray[Int64,9](fill=0)
    var labels=InlineArray[Int,6](fill=0); var masks=InlineArray[Int,10](fill=0)
    var edge_count=1; var node_count=2
    eu[0]=0; ev[0]=1; ew[0]=2*matrix[1]
    labels[0]=0; labels[1]=1; masks[0]=1; masks[1]=2
    for leaf in range(2,n):
        var limb=Int64(9223372036854775807)
        for i in range(leaf):
            for j in range(i+1,leaf): limb=min(limb,matrix[6*i+leaf]+matrix[6*j+leaf]-matrix[6*i+j])
        if limb<0: return 0
        var first = -1; var second = -1; var attachment=Int64(0)
        for i in range(leaf):
            if first>=0: break
            for j in range(i+1,leaf):
                let a=2*matrix[6*i+leaf]-limb; let b=2*matrix[6*j+leaf]-limb
                if a>=0 and b>=0 and a+b==2*matrix[6*i+j]:
                    first=i; second=j; attachment=a; break
        if first<0: return 0
        let start=labels[first]; let target=labels[second]
        var parent=InlineArray[Int,10](fill=-1); var parent_edge=InlineArray[Int,10](fill=-1)
        var distances=InlineArray[Int64,10](fill=0)
        phylo_paths(node_count,edge_count,eu,ev,ew,start,parent,parent_edge,distances)
        if parent[target]<0: return 0
        var path=InlineArray[Int,10](fill=0)
        var count=0; var current=target
        while current!=start:
            path[count]=current; count+=1; current=parent[current]
        var node=start; var elapsed=Int64(0); var attach = -1
        for step in range(count+1):
            if elapsed==attachment: attach=node; break
            if step==count: break
            let next=path[count-1-step]; let e=parent_edge[next]; let weight=ew[e]
            if elapsed<attachment and attachment<elapsed+weight:
                if node_count>=10 or edge_count>=9: return 0
                let internal=node_count; node_count+=1
                eu[e]=node; ev[e]=internal; ew[e]=attachment-elapsed
                eu[edge_count]=internal; ev[edge_count]=next; ew[edge_count]=weight-ew[e]; edge_count+=1
                attach=internal; break
            elapsed+=weight; node=next
        if attach<0: return 0
        if limb==0:
            if masks[attach]!=0: return 0
            labels[leaf]=attach; masks[attach] |= 1 << leaf
        else:
            if node_count>=10 or edge_count>=9: return 0
            let fresh=node_count; node_count+=1
            labels[leaf]=fresh; masks[fresh]=1 << leaf
            eu[edge_count]=attach; ev[edge_count]=fresh; ew[edge_count]=limb; edge_count+=1
    for i in range(n):
        var parent=InlineArray[Int,10](fill=-1); var parent_edge=InlineArray[Int,10](fill=-1)
        var distances=InlineArray[Int64,10](fill=0)
        phylo_paths(node_count,edge_count,eu,ev,ew,labels[i],parent,parent_edge,distances)
        for j in range(i+1,n):
            if parent[labels[j]]<0 or distances[labels[j]]!=2*matrix[6*i+j]: return 0
    var record_masks=InlineArray[Int,9](fill=0); var record_weights=InlineArray[Int64,9](fill=0)
    for excluded in range(edge_count):
        var queue=InlineArray[Int,10](fill=0); var seen=InlineArray[Bool,10](fill=False)
        var head=0; var tail=1; var mask=0
        queue[0]=eu[excluded]; seen[eu[excluded]]=True
        while head<tail:
            let node=queue[head]; head+=1; mask |= masks[node]
            for e in range(edge_count):
                if e==excluded: continue
                var other = -1
                if eu[e]==node: other=ev[e]
                elif ev[e]==node: other=eu[e]
                if other<0 or seen[other]: continue
                seen[other]=True; queue[tail]=other; tail+=1
        if (mask & 1)==0: mask=((1 << n)-1) ^ mask
        var j=excluded
        while j>0 and (record_masks[j-1]>mask or (record_masks[j-1]==mask and record_weights[j-1]>ew[excluded])):
            record_masks[j]=record_masks[j-1]; record_weights[j]=record_weights[j-1]; j-=1
        record_masks[j]=mask; record_weights[j]=ew[excluded]
    let bytes=8*(1+2*edge_count)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    for i in range(1+2*edge_count):
        var value=Int64(edge_count)
        if i>0:
            let e=(i-1)//2
            value=Int64(record_masks[e]) if (i & 1)==1 else record_weights[e]
        let bits=bitcast[UInt64](value)
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(bytes)

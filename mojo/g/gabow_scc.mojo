from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 40
comptime MAX_M = 2047
comptime MAX_INPUT = 4096
comptime MAX_OUTPUT = 81

@export("gabow_scc")
fn gabow_scc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<2 or length>c_size_t(MAX_INPUT): return -1
    let nv=input[0]; let mv=input[1]
    if nv<0 or nv>MAX_N or mv<0 or mv>MAX_M: return -1
    let n=Int(nv); let m=Int(mv)
    if Int(length)!=2+2*m: return -1
    var adjacency=InlineArray[UInt64, MAX_N](fill=0)
    var neighbors=InlineArray[Int, MAX_N*MAX_N](fill=0)
    var degree=InlineArray[Int, MAX_N](fill=0)
    for e in range(m):
        let source=input[2+2*e]; let target=input[3+2*e]
        if source<0 or target<0 or source>=nv or target>=nv: return -1
        let u=Int(source); let v=Int(target); let bit=UInt64(1)<<UInt64(v)
        if (adjacency[u]&bit)==0:
            adjacency[u] |= bit
            neighbors[u*MAX_N+degree[u]]=v; degree[u]+=1
    var preorder=InlineArray[Int64, MAX_N](fill=-1)
    var component=InlineArray[Int64, MAX_N](fill=-1)
    var vertices=InlineArray[Int, MAX_N](fill=0)
    var boundaries=InlineArray[Int, MAX_N](fill=0)
    var dfs=InlineArray[Int, MAX_N](fill=0)
    var next_neighbor=InlineArray[Int, MAX_N](fill=0)
    var vertex_count=0; var boundary_count=0; var depth=0
    var clock=0; var component_count=0
    for root in range(n):
        if preorder[root]>=0: continue
        preorder[root]=Int64(clock); clock+=1
        vertices[vertex_count]=root; vertex_count+=1
        boundaries[boundary_count]=root; boundary_count+=1
        dfs[depth]=root; next_neighbor[depth]=0; depth+=1
        while depth>0:
            let frame=depth-1; let v=dfs[frame]
            if next_neighbor[frame]<degree[v]:
                let w=neighbors[v*MAX_N+next_neighbor[frame]]
                next_neighbor[frame]+=1
                if preorder[w]<0:
                    preorder[w]=Int64(clock); clock+=1
                    vertices[vertex_count]=w; vertex_count+=1
                    boundaries[boundary_count]=w; boundary_count+=1
                    dfs[depth]=w; next_neighbor[depth]=0; depth+=1
                elif component[w]<0:
                    while boundary_count>0 and preorder[boundaries[boundary_count-1]]>preorder[w]: boundary_count-=1
            else:
                depth-=1
                if boundary_count>0 and boundaries[boundary_count-1]==v:
                    boundary_count-=1
                    while True:
                        vertex_count-=1; let member=vertices[vertex_count]
                        component[member]=Int64(component_count)
                        if member==v: break
                    component_count+=1
    var staged=InlineArray[UInt8, MAX_OUTPUT](fill=0)
    var position=1; staged[0]=UInt8(component_count)
    for first in range(n):
        let id=component[first]
        var seen=False
        for earlier in range(first):
            if component[earlier]==id: seen=True
        if seen: continue
        var size=0
        for v in range(first,n):
            if component[v]==id: size+=1
        staged[position]=UInt8(size); position+=1
        for v in range(first,n):
            if component[v]==id: staged[position]=UInt8(v); position+=1
    if output==UnsafePointer[UInt8, MutAnyOrigin]() or capacity<c_size_t(position): return -2
    for q in range(position): output[q]=staged[q]
    return Int64(position)

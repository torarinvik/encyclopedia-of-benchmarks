package gabow_scc

import "core:c"

@(export)
gabow_scc :: proc "c" (input:[^]i64, length:c.size_t,
    output:[^]u8, output_capacity:c.size_t)->i64 {
    N :: 40; M :: 2047; MAX_OUTPUT :: 81
    if input==nil || length<2 || length>4096 do return -1
    if input[0]<0 || input[0]>N || input[1]<0 || input[1]>M do return -1
    n,m:=int(input[0]),int(input[1])
    if length!=c.size_t(2+2*m) do return -1
    var adjacency:[N]u64
    var neighbors:[N*N]int; var degree:[N]int
    for e:=0; e<m; e+=1 {
        source,target:=input[2+2*e],input[3+2*e]
        if source<0 || target<0 || source>=i64(n) || target>=i64(n) do return -1
        u,v:=int(source),int(target); bit:=u64(1)<<u64(v)
        if adjacency[u]&bit==0 { adjacency[u]|=bit; neighbors[u*N+degree[u]]=v; degree[u]+=1 }
    }
    var preorder:[N]i64; var component:[N]i64
    var vertices,boundaries,dfs,next_neighbor:[N]int
    for v:=0; v<n; v+=1 { preorder[v]=-1; component[v]=-1 }
    vertex_count,boundary_count,depth,clock,component_count:=0,0,0,0,0
    for root:=0; root<n; root+=1 {
        if preorder[root]>=0 do continue
        preorder[root]=i64(clock); clock+=1
        vertices[vertex_count]=root; vertex_count+=1
        boundaries[boundary_count]=root; boundary_count+=1
        dfs[depth]=root; next_neighbor[depth]=0; depth+=1
        for depth>0 {
            frame:=depth-1; v:=dfs[frame]
            if next_neighbor[frame]<degree[v] {
                w:=neighbors[v*N+next_neighbor[frame]]; next_neighbor[frame]+=1
                if preorder[w]<0 {
                    preorder[w]=i64(clock); clock+=1
                    vertices[vertex_count]=w; vertex_count+=1
                    boundaries[boundary_count]=w; boundary_count+=1
                    dfs[depth]=w; next_neighbor[depth]=0; depth+=1
                } else if component[w]<0 {
                    for boundary_count>0 && preorder[boundaries[boundary_count-1]]>preorder[w] { boundary_count-=1 }
                }
            } else {
                depth-=1
                if boundary_count>0 && boundaries[boundary_count-1]==v {
                    boundary_count-=1
                    for {
                        vertex_count-=1; member:=vertices[vertex_count]
                        component[member]=i64(component_count)
                        if member==v { break }
                    }
                    component_count+=1
                }
            }
        }
    }
    var staged:[MAX_OUTPUT]u8; position:=1; staged[0]=u8(component_count)
    for first:=0; first<n; first+=1 {
        id:=component[first]; seen:=false
        for earlier:=0; earlier<first; earlier+=1 { if component[earlier]==id { seen=true } }
        if seen do continue
        size:=0
        for v:=first; v<n; v+=1 { if component[v]==id { size+=1 } }
        staged[position]=u8(size); position+=1
        for v:=first; v<n; v+=1 { if component[v]==id { staged[position]=u8(v); position+=1 } }
    }
    if output==nil || output_capacity<c.size_t(position) do return -2
    for q:=0; q<position; q+=1 { output[q]=staged[q] }
    return i64(position)
}

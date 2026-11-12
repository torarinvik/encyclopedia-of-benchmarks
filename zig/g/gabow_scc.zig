export fn gabow_scc(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    const N: usize=40; const M: usize=2047; const MAX_OUTPUT: usize=81;
    if (input_opt==null or length<2 or length>4096) return -1;
    const input=input_opt.?;
    if (input[0]<0 or input[0]>40 or input[1]<0 or input[1]>2047) return -1;
    const n: usize=@intCast(input[0]); const m: usize=@intCast(input[1]);
    if (length!=2+2*m) return -1;
    var adjacency: [N]u64=@splat(0);
    var neighbors: [N*N]usize=@splat(0); var degree: [N]usize=@splat(0);
    for (0..m) |e| {
        const source=input[2+2*e]; const target=input[3+2*e];
        if (source<0 or target<0 or source>=@as(i64,@intCast(n)) or target>=@as(i64,@intCast(n))) return -1;
        const u: usize=@intCast(source); const v: usize=@intCast(target);
        const bit=@as(u64,1)<<@intCast(v);
        if ((adjacency[u]&bit)==0) { adjacency[u]|=bit; neighbors[u*N+degree[u]]=v; degree[u]+=1; }
    }
    var preorder: [N]i64=@splat(-1); var component: [N]i64=@splat(-1);
    var vertices: [N]usize=@splat(0); var boundaries: [N]usize=@splat(0);
    var dfs: [N]usize=@splat(0); var next_neighbor: [N]usize=@splat(0);
    var vertex_count: usize=0; var boundary_count: usize=0; var depth: usize=0;
    var clock: usize=0; var component_count: usize=0;
    for (0..n) |root| {
        if (preorder[root]>=0) continue;
        preorder[root]=@intCast(clock); clock+=1;
        vertices[vertex_count]=root; vertex_count+=1;
        boundaries[boundary_count]=root; boundary_count+=1;
        dfs[depth]=root; next_neighbor[depth]=0; depth+=1;
        while (depth>0) {
            const frame=depth-1; const v=dfs[frame];
            if (next_neighbor[frame]<degree[v]) {
                const w=neighbors[v*N+next_neighbor[frame]]; next_neighbor[frame]+=1;
                if (preorder[w]<0) {
                    preorder[w]=@intCast(clock); clock+=1;
                    vertices[vertex_count]=w; vertex_count+=1;
                    boundaries[boundary_count]=w; boundary_count+=1;
                    dfs[depth]=w; next_neighbor[depth]=0; depth+=1;
                } else if (component[w]<0) {
                    while (boundary_count>0 and preorder[boundaries[boundary_count-1]]>preorder[w]) : (boundary_count-=1) {}
                }
            } else {
                depth-=1;
                if (boundary_count>0 and boundaries[boundary_count-1]==v) {
                    boundary_count-=1;
                    while (true) {
                        vertex_count-=1; const member=vertices[vertex_count];
                        component[member]=@intCast(component_count);
                        if (member==v) break;
                    }
                    component_count+=1;
                }
            }
        }
    }
    var staged: [MAX_OUTPUT]u8=@splat(0); var position: usize=1;
    staged[0]=@intCast(component_count);
    for (0..n) |first| {
        const id=component[first]; var seen=false;
        for (0..first) |earlier| { if (component[earlier]==id) seen=true; }
        if (seen) continue;
        var size: usize=0;
        for (first..n) |v| { if (component[v]==id) size+=1; }
        staged[position]=@intCast(size); position+=1;
        for (first..n) |v| { if (component[v]==id) { staged[position]=@intCast(v); position+=1; } }
    }
    if (output_opt==null or output_capacity<position) return -2;
    const output=output_opt.?;
    for (0..position) |q| output[q]=staged[q];
    return @intCast(position);
}

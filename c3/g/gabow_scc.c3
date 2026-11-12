module gabow_scc;

fn long gabow_scc(long* input, usz length, char* output, usz output_capacity)
    @export("gabow_scc") {
    const usz N=40, M=2047, MAX_INPUT=4096, MAX_OUTPUT=81;
    if (input==null || length<2 || length>MAX_INPUT) return -1;
    if (input[0]<0 || input[0]>(long)N || input[1]<0 || input[1]>(long)M) return -1;
    usz n=(usz)input[0], m=(usz)input[1];
    if (length!=2+2*m) return -1;
    ulong adjacency[N]={0}; usz neighbors[N*N]={0}, degree[N]={0};
    for (usz e=0; e<m; e++) {
        long source=input[2+2*e], target=input[3+2*e];
        if (source<0 || target<0 || (ulong)source>=(ulong)n || (ulong)target>=(ulong)n) return -1;
        usz u=(usz)source, v=(usz)target; ulong bit=1ul << (ulong)v;
        if ((adjacency[u]&bit)==0ul) { adjacency[u] |= bit; neighbors[u*N+degree[u]++]=v; }
    }
    long preorder[N], component[N];
    usz vertices[N], boundaries[N], dfs[N], next_neighbor[N];
    for (usz v=0; v<n; v++) { preorder[v]=-1; component[v]=-1; }
    usz vertex_count=0, boundary_count=0, depth=0, clock=0, component_count=0;
    for (usz root=0; root<n; root++) {
        if (preorder[root]>=0) continue;
        preorder[root]=(long)clock++;
        vertices[vertex_count++]=root; boundaries[boundary_count++]=root;
        dfs[depth]=root; next_neighbor[depth]=0; depth++;
        while (depth>0) {
            usz frame=depth-1, v=dfs[frame];
            if (next_neighbor[frame]<degree[v]) {
                usz w=neighbors[v*N+next_neighbor[frame]++];
                if (preorder[w]<0) {
                    preorder[w]=(long)clock++;
                    vertices[vertex_count++]=w; boundaries[boundary_count++]=w;
                    dfs[depth]=w; next_neighbor[depth]=0; depth++;
                } else if (component[w]<0) {
                    while (boundary_count>0 && preorder[boundaries[boundary_count-1]]>preorder[w]) boundary_count--;
                }
            } else {
                depth--;
                if (boundary_count>0 && boundaries[boundary_count-1]==v) {
                    boundary_count--;
                    for (;;) {
                        usz member=vertices[--vertex_count]; component[member]=(long)component_count;
                        if (member==v) break;
                    }
                    component_count++;
                }
            }
        }
    }
    char staged[MAX_OUTPUT]; usz position=1; staged[0]=(char)component_count;
    for (usz first=0; first<n; first++) {
        long id=component[first]; bool seen=false;
        for (usz earlier=0; earlier<first; earlier++) if (component[earlier]==id) seen=true;
        if (seen) continue;
        usz size=0;
        for (usz v=first; v<n; v++) if (component[v]==id) size++;
        staged[position++]=(char)size;
        for (usz v=first; v<n; v++) if (component[v]==id) staged[position++]=(char)v;
    }
    if (output==null || output_capacity<position) return -2;
    for (usz q=0; q<position; q++) output[q]=staged[q];
    return (long)position;
}

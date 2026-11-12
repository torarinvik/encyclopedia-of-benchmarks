#[no_mangle]
pub unsafe extern "C" fn gabow_scc(input: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    const N: usize=40; const M: usize=2047; const MAX_INPUT: usize=4096; const MAX_OUTPUT: usize=81;
    if input.is_null() || length<2 || length>MAX_INPUT { return -1; }
    let nv=*input; let mv=*input.add(1);
    if nv<0 || nv>N as i64 || mv<0 || mv>M as i64 { return -1; }
    let n=nv as usize; let m=mv as usize;
    if length!=2+2*m { return -1; }
    let mut adjacency=[0u64;N]; let mut neighbors=[0usize;N*N]; let mut degree=[0usize;N];
    for e in 0..m {
        let source=*input.add(2+2*e); let target=*input.add(3+2*e);
        if source<0 || target<0 || source>=n as i64 || target>=n as i64 { return -1; }
        let u=source as usize; let v=target as usize; let bit=1u64<<v;
        if adjacency[u]&bit==0 { adjacency[u]|=bit; neighbors[u*N+degree[u]]=v; degree[u]+=1; }
    }
    let mut preorder=[-1i64;N]; let mut component=[-1i64;N];
    let mut vertices=[0usize;N]; let mut boundaries=[0usize;N];
    let mut dfs=[0usize;N]; let mut next_neighbor=[0usize;N];
    let (mut vertex_count,mut boundary_count,mut depth,mut clock,mut component_count)=(0usize,0usize,0usize,0usize,0usize);
    for root in 0..n {
        if preorder[root]>=0 { continue; }
        preorder[root]=clock as i64; clock+=1;
        vertices[vertex_count]=root; vertex_count+=1;
        boundaries[boundary_count]=root; boundary_count+=1;
        dfs[depth]=root; next_neighbor[depth]=0; depth+=1;
        while depth>0 {
            let frame=depth-1; let v=dfs[frame];
            if next_neighbor[frame]<degree[v] {
                let w=neighbors[v*N+next_neighbor[frame]]; next_neighbor[frame]+=1;
                if preorder[w]<0 {
                    preorder[w]=clock as i64; clock+=1;
                    vertices[vertex_count]=w; vertex_count+=1;
                    boundaries[boundary_count]=w; boundary_count+=1;
                    dfs[depth]=w; next_neighbor[depth]=0; depth+=1;
                } else if component[w]<0 {
                    while boundary_count>0 && preorder[boundaries[boundary_count-1]]>preorder[w] { boundary_count-=1; }
                }
            } else {
                depth-=1;
                if boundary_count>0 && boundaries[boundary_count-1]==v {
                    boundary_count-=1;
                    loop {
                        vertex_count-=1; let member=vertices[vertex_count];
                        component[member]=component_count as i64;
                        if member==v { break; }
                    }
                    component_count+=1;
                }
            }
        }
    }
    let mut staged=[0u8;MAX_OUTPUT]; let mut position=1usize; staged[0]=component_count as u8;
    for first in 0..n {
        let id=component[first]; if component[..first].contains(&id) { continue; }
        let mut size=0usize; for v in first..n { if component[v]==id { size+=1; } }
        staged[position]=size as u8; position+=1;
        for v in first..n { if component[v]==id { staged[position]=v as u8; position+=1; } }
    }
    if output.is_null() || output_capacity<position { return -2; }
    for q in 0..position { *output.add(q)=staged[q]; }
    position as i64
}

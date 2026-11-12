const MAX_N: usize = 10;
const MAX_M: usize = 45;
const MAX_INPUT: usize = 92;
const MAX_DN: usize = 20;

fn pair_vertex_flow(adjacency: &[u64; MAX_N], n: usize, source_vertex: usize,
                    target_vertex: usize, limit: i64) -> i64 {
    let mut residual = [[0i64; MAX_DN]; MAX_DN];
    let nodes = 2*n;
    for v in 0..n {
        residual[2*v][2*v+1] = if v == source_vertex || v == target_vertex { n as i64 } else { 1 };
    }
    for u in 0..n { for v in (u+1)..n {
        if adjacency[u] & (1u64 << v) != 0 {
            residual[2*u+1][2*v] = 1;
            residual[2*v+1][2*u] = 1;
        }
    }}
    let source=2*source_vertex+1; let sink=2*target_vertex;
    let mut flow=0i64;
    while flow<limit {
        let mut parent=[-1i32;MAX_DN]; let mut queue=[0usize;MAX_DN];
        parent[source]=source as i32; let mut head=0usize; let mut tail=0usize; queue[tail]=source; tail+=1;
        while head<tail && parent[sink]<0 {
            let u=queue[head]; head+=1;
            for v in 0..nodes {
                if parent[v]<0 && residual[u][v]>0 {
                    parent[v]=u as i32; queue[tail]=v; tail+=1;
                    if v==sink { break; }
                }
            }
        }
        if parent[sink]<0 { break; }
        let mut amount=limit-flow; let mut v=sink;
        while v!=source { let u=parent[v] as usize; amount=amount.min(residual[u][v]); v=u; }
        v=sink;
        while v!=source { let u=parent[v] as usize; residual[u][v]-=amount; residual[v][u]+=amount; v=u; }
        flow+=amount;
    }
    flow
}

#[no_mangle]
pub unsafe extern "C" fn vertex_connectivity(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length<2 || length>MAX_INPUT { return -1; }
    let nv=*input; let mv=*input.add(1);
    if nv<0 || nv>MAX_N as i64 || mv<0 || mv>MAX_M as i64 { return -1; }
    let n=nv as usize; let m=mv as usize;
    if length!=2+2*m { return -1; }
    let mut adjacency=[0u64;MAX_N];
    for e in 0..m {
        let left=*input.add(2+2*e); let right=*input.add(3+2*e);
        if left<0 || right<0 || left>=n as i64 || right>=n as i64 { return -1; }
        if left!=right { adjacency[left as usize]|=1u64<<(right as usize); adjacency[right as usize]|=1u64<<(left as usize); }
    }
    if n<=1 { return 0; }
    let mut reached=1u64; let mut queue=[0usize;MAX_N]; let mut head=0usize; let mut tail=0usize; queue[tail]=0; tail+=1;
    while head<tail {
        let u=queue[head]; head+=1;
        for v in 0..n { let bit=1u64<<v; if adjacency[u]&bit!=0 && reached&bit==0 { reached|=bit; queue[tail]=v; tail+=1; } }
    }
    if reached!=(1u64<<n)-1 { return 0; }
    let mut best=n as i64-1;
    for source in 0..n { for target in (source+1)..n {
        if adjacency[source]&(1u64<<target)!=0 { continue; }
        let flow=pair_vertex_flow(&adjacency,n,source,target,best);
        if flow<best { best=flow; }
        if best==0 { return 0; }
    }}
    best
}

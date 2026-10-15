const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const INF_FLOW: i64 = 6401;

fn dfs(u: usize, sink: usize, pushed: i64, residual: &mut [[i64; MAX_VERTICES]; MAX_VERTICES], level: &[i32; MAX_VERTICES], next: &mut [usize; MAX_VERTICES], n: usize) -> i64 {
    if u == sink { return pushed; }
    while next[u] < n {
        let v=next[u];
        if level[v] == level[u]+1 && residual[u][v] > 0 {
            let sent=dfs(v,sink,pushed.min(residual[u][v]),residual,level,next,n);
            if sent>0 {residual[u][v]-=sent;residual[v][u]+=sent;return sent;}
        }
        next[u]+=1;
    }
    0
}

/// Return the maximum flow for a bounded directed graph edge list.
#[no_mangle]
pub unsafe extern "C" fn dinic_maxflow(input: *const i64,length:usize)->i64 {
    if input.is_null()||length<4{return -1;}
    let v=std::slice::from_raw_parts(input,length);
    let (nv,mv,sv,tv)=(v[0],v[1],v[2],v[3]);
    if !(2..=16).contains(&nv)||!(0..=64).contains(&mv)||sv<1||sv>nv||tv<1||tv>nv||sv==tv{return -1;}
    let(n,m,s,t)=(nv as usize,mv as usize,(sv-1)as usize,(tv-1)as usize);
    if length!=4+3*m{return -1;}
    let mut residual=[[0i64;MAX_VERTICES];MAX_VERTICES];
    for i in 0..m {let u=v[4+3*i];let w=v[5+3*i];let c=v[6+3*i];if u<1||u>nv||w<1||w>nv||u==w||!(0..=100).contains(&c){return -1;}residual[(u-1)as usize][(w-1)as usize]+=c;}
    let mut flow=0i64;
    loop {let mut level=[-1i32;MAX_VERTICES];let mut queue=[0usize;MAX_VERTICES];let(mut head,mut tail)=(0,0);level[s]=0;queue[tail]=s;tail+=1;
        while head<tail {let u=queue[head];head+=1;for w in 0..n {if residual[u][w]>0&&level[w]<0{level[w]=level[u]+1;queue[tail]=w;tail+=1;}}}
        if level[t]<0{break;}let mut next=[0usize;MAX_VERTICES];loop{let pushed=dfs(s,t,INF_FLOW,&mut residual,&level,&mut next,n);if pushed==0{break;}flow+=pushed;}
    }flow
}

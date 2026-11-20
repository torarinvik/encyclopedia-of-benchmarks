use core::slice;

const N: usize = 8;
const M: usize = 14;
const MAX_INPUT: usize = 54;
const MAX_OUTPUT: usize = 72;
const INF: i64 = i64::MAX / 4;

#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize, w: i64 }
#[derive(Clone, Copy, Default)]
struct Candidate { a: usize, b: usize, left: usize, right: usize, edge: usize, w: i64 }
#[derive(Clone, Copy)]
struct Graph { n: usize, m: usize, k: usize, terminals: [usize; N], edges: [Edge; M] }

fn find(parent: &mut [usize; N], mut x: usize) -> usize {
    while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; }
    x
}
fn join(parent: &mut [usize; N], rank: &mut [usize; N], a: usize, b: usize) -> bool {
    let mut ra = find(parent, a); let mut rb = find(parent, b);
    if ra == rb { return false; }
    if rank[ra] < rank[rb] { core::mem::swap(&mut ra, &mut rb); }
    parent[rb] = ra;
    if rank[ra] == rank[rb] { rank[ra] += 1; }
    true
}
fn cand_before(a: Candidate, b: Candidate) -> bool {
    (a.w, a.a, a.b, a.left, a.right, a.edge) < (b.w, b.a, b.b, b.left, b.right, b.edge)
}
fn parse(input: &[i64]) -> Option<Graph> {
    if input.len() < 3 || input.len() > MAX_INPUT { return None; }
    let (n0,m0,k0)=(input[0],input[1],input[2]);
    if !(2..=N as i64).contains(&n0) || !(1..=M as i64).contains(&m0) || k0<2 || k0>n0 { return None; }
    let (n,m,k)=(n0 as usize,m0 as usize,k0 as usize);
    if input.len() < 3+k+3*m { return None; }
    let mut terminals=[0usize;N]; let mut term=[false;N]; let mut at=3;
    for i in 0..k { let t=input[at];at+=1;if t<0||t>=n0||term[t as usize]{return None;}terminals[i]=t as usize;term[t as usize]=true; }
    let mut edges=[Edge::default();M]; let mut pairs=[[false;N];N];
    for e in 0..m { let (u,v,w)=(input[at],input[at+1],input[at+2]);at+=3;
        if u<0||u>=v||v>=n0||!(1..=9).contains(&w){return None;}let (u,v)=(u as usize,v as usize);if pairs[u][v]{return None;}pairs[u][v]=true;edges[e]=Edge{u,v,w};
    }
    if at!=input.len(){return None;}
    let mut seen=[false;N];let mut q=[0usize;N];let(mut head,mut tail)=(0,0);seen[0]=true;q[tail]=0;tail+=1;
    while head<tail {let u=q[head];head+=1;for edge in edges.iter().take(m){let v=if edge.u==u{Some(edge.v)}else if edge.v==u{Some(edge.u)}else{None};if let Some(v)=v{if !seen[v]{seen[v]=true;q[tail]=v;tail+=1;}}}}
    if (0..n).any(|v|!seen[v]){return None;}
    Some(Graph{n,m,k,terminals,edges})
}
fn solve(g: &Graph) -> Option<(i64,[usize;M],usize)> {
    let mut d=[INF;N];let mut owner=[g.n;N];let mut pred=[usize::MAX;N];let mut pe=[usize::MAX;N];let mut done=[false;N];
    for i in 0..g.k{let t=g.terminals[i];d[t]=0;owner[t]=t;}
    for _ in 0..g.n {let mut best:Option<usize>=None;for v in 0..g.n{if !done[v]&&best.map_or(true,|u| (d[v],owner[v],v)<(d[u],owner[u],u)){best=Some(v);}}
        let Some(u)=best else{break};if d[u]==INF{break;}done[u]=true;
        for e in 0..g.m {let edge=g.edges[e];let v=if edge.u==u{Some(edge.v)}else if edge.v==u{Some(edge.u)}else{None};if let Some(v)=v{let nd=d[u]+edge.w;
            if nd<d[v]||(nd==d[v]&&owner[u]<owner[v]){d[v]=nd;owner[v]=owner[u];pred[v]=u;pe[v]=e;}
            else if nd==d[v]&&owner[u]==owner[v]&&!done[v]&&(pred[v]==usize::MAX||(u,e)<(pred[v],pe[v])){pred[v]=u;pe[v]=e;}
        }}
    }
    if (0..g.n).any(|v|d[v]==INF||owner[v]==g.n){return None;}
    let mut has=[[false;N];N];let mut best=[[Candidate::default();N];N];
    for e in 0..g.m{let edge=g.edges[e];let(mut a,mut b)=(owner[edge.u],owner[edge.v]);if a==b{continue;}let(mut left,mut right)=(edge.u,edge.v);if a>b{core::mem::swap(&mut a,&mut b);core::mem::swap(&mut left,&mut right);}
        let c=Candidate{a,b,left,right,edge:e,w:d[edge.u]+edge.w+d[edge.v]};if !has[a][b]||cand_before(c,best[a][b]){best[a][b]=c;has[a][b]=true;}
    }
    let mut candidates=[Candidate::default();M];let mut cn=0;for a in 0..g.n{for b in a+1..g.n{if has[a][b]{candidates[cn]=best[a][b];cn+=1;}}}
    for i in 1..cn{let x=candidates[i];let mut j=i;while j>0&&cand_before(x,candidates[j-1]){candidates[j]=candidates[j-1];j-=1;}candidates[j]=x;}
    let mut parent=[0usize;N];let mut rank=[0usize;N];for v in 0..g.n{parent[v]=v;}let mut chosen=[0usize;N];let mut ch=0;
    for i in 0..cn{if ch==g.k-1{break;}if join(&mut parent,&mut rank,candidates[i].a,candidates[i].b){chosen[ch]=i;ch+=1;}}
    if ch!=g.k-1{return None;}
    let mut used=[false;M];for i in 0..ch{let c=candidates[chosen[i]];used[c.edge]=true;let mut x=c.left;while x!=c.a{if pe[x]==usize::MAX{return None;}used[pe[x]]=true;x=pred[x];}x=c.right;while x!=c.b{if pe[x]==usize::MAX{return None;}used[pe[x]]=true;x=pred[x];}}
    let mut order=[0usize;M];let mut on=0;for e in 0..g.m{if used[e]{order[on]=e;on+=1;}}
    for i in 1..on{let x=order[i];let mut j=i;while j>0&&(g.edges[x].w,x)<(g.edges[order[j-1]].w,order[j-1]){order[j]=order[j-1];j-=1;}order[j]=x;}
    for v in 0..g.n{parent[v]=v;rank[v]=0;}let mut tree=[false;M];for &e in order.iter().take(on){let edge=g.edges[e];if join(&mut parent,&mut rank,edge.u,edge.v){tree[e]=true;}}
    let r=find(&mut parent,g.terminals[0]);for i in 1..g.k{if find(&mut parent,g.terminals[i])!=r{return None;}}
    let mut is_term=[false;N];let mut degree=[0usize;N];for i in 0..g.k{is_term[g.terminals[i]]=true;}for e in 0..g.m{if tree[e]{degree[g.edges[e].u]+=1;degree[g.edges[e].v]+=1;}}
    let mut queue=[0usize;N];let(mut head,mut tail)=(0,0);let mut queued=[false;N];for v in 0..g.n{if !is_term[v]&&degree[v]<=1{queue[tail]=v;tail+=1;queued[v]=true;}}
    while head<tail{let u=queue[head];head+=1;if degree[u]>1{continue;}for e in 0..g.m{if tree[e]&&(g.edges[e].u==u||g.edges[e].v==u){tree[e]=false;let v=if g.edges[e].u==u{g.edges[e].v}else{g.edges[e].u};degree[u]-=1;degree[v]-=1;if !is_term[v]&&degree[v]<=1&&!queued[v]{queue[tail]=v;tail+=1;queued[v]=true;}}}}
    let mut out=[0usize;M];let mut count=0;let mut cost=0i64;for e in 0..g.m{if tree[e]{out[count]=e;count+=1;cost+=g.edges[e].w;}}
    if count==0||count>g.n-1{return None;}Some((cost,out,count))
}
fn put(out:&mut [u8],at:usize,value:i64){out[at..at+8].copy_from_slice(&value.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn steiner_tree_mehlhorn_voronoi_mst(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3||length>MAX_INPUT{return -1;}let values=slice::from_raw_parts(input,length);let Some(g)=parse(values)else{return -1;};let Some((cost,edges,count))=solve(&g)else{return -1;};
    let bytes=(2+count)*8;if output.is_null()||capacity<bytes||bytes>MAX_OUTPUT{return -2;}let out=slice::from_raw_parts_mut(output,bytes);put(out,0,cost);put(out,8,count as i64);for i in 0..count{put(out,16+i*8,edges[i] as i64);}bytes as i64
}

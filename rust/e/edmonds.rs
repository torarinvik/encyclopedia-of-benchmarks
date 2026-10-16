const NMAX: usize = 5; const EMAX: usize = 12; const INF: i64 = 1_000_000_000;
#[derive(Clone,Copy)] struct Edge {u:usize,v:usize,w:i64}
#[no_mangle] pub unsafe extern "C" fn edmonds(a:*const i64,len:usize)->i64 {
 if a.is_null()||len<3||len>39{return -1} let x=std::slice::from_raw_parts(a,len);let (n0,r0,m0)=(x[0],x[1],x[2]);
 if n0<1||n0>NMAX as i64||r0<0||r0>=n0||m0<0||m0>EMAX as i64||len!=3+3*m0 as usize{return -1}
 let(mut n,mut root,mut m)=(n0 as usize,r0 as usize,m0 as usize);let mut e=[Edge{u:0,v:0,w:0};EMAX];
 for i in 0..m {let(u,v,w)=(x[3+3*i],x[4+3*i],x[5+3*i]);if u<0||u>=n as i64||v<0||v>=n as i64||w<0||w>100{return -1} e[i]=Edge{u:u as usize,v:v as usize,w};}
 let mut answer=0i64;loop{
 let(mut inn,mut pre)=([INF;NMAX],[usize::MAX;NMAX]);for z in 0..m{let q=e[z];if q.u!=q.v&&q.v!=root&&q.w<inn[q.v]{inn[q.v]=q.w;pre[q.v]=q.u;}}
 inn[root]=0;if (0..n).any(|i|inn[i]==INF){return -1}
 let(mut id,mut vis)=([-1i32;NMAX],[-1i32;NMAX]);let mut cycles=0i32;
 for i in 0..n{answer+=inn[i];let mut v=i;while vis[v]!=i as i32&&id[v]==-1&&v!=root{vis[v]=i as i32;v=pre[v];}if v!=root&&id[v]==-1{let mut u=pre[v];while u!=v{id[u]=cycles;u=pre[u];}id[v]=cycles;cycles+=1;}}
 if cycles==0{return answer}let mut member=[false;NMAX];for i in 0..n{member[i]=id[i]>=0;}for i in 0..n{if id[i]<0{id[i]=cycles;cycles+=1;}}
 let mut ne=[Edge{u:0,v:0,w:0};EMAX];for z in 0..m{let q=e[z];let(u,v)=(id[q.u] as usize,id[q.v] as usize);let mut w=q.w;if u!=v{w-=inn[q.v];}ne[z]=Edge{u,v,w};}
 root=id[root] as usize;n=cycles as usize;e=ne; m=m;
 }
}

const MAX_N: usize=16;
const MAX_M: i64=64;
fn root(parent:&mut [usize;MAX_N],mut x:usize)->usize{while parent[x]!=x{parent[x]=parent[parent[x]];x=parent[x];}x}
/// Return the total weight of a bounded connected undirected graph's MST.
#[no_mangle]
pub unsafe extern "C" fn boruvkas_minimum_spanning_tree(input:*const i64,length:usize)->i64{
    if input.is_null()||length<2{return -1;}let a=std::slice::from_raw_parts(input,length);let(nv,mv)=(a[0],a[1]);
    if !(2..=16).contains(&nv)||mv<nv-1||mv>MAX_M||mv>nv*(nv-1)/2{return -1;}let(n,m)=(nv as usize,mv as usize);if length!=2+3*m{return -1;}
    let mut w=[[i64::MAX;MAX_N];MAX_N];for k in 0..m{let(u,v,x)=(a[2+3*k],a[3+3*k],a[4+3*k]);if u<1||u>nv||v<1||v>nv||u==v||!(1..=100).contains(&x)||w[(u-1)as usize][(v-1)as usize]!=i64::MAX{return -1;}let(u,v)=((u-1)as usize,(v-1)as usize);w[u][v]=x;w[v][u]=x;}
    let mut p=[0usize;MAX_N];for i in 0..n{p[i]=i;}let mut components=n;let mut total=0i64;
    while components>1{let(mut bu,mut bv)=([-1isize;MAX_N],[-1isize;MAX_N]);let mut bw=[i64::MAX;MAX_N];
        for u in 0..n{for v in u+1..n{if w[u][v]!=i64::MAX{let(a,b)=(root(&mut p,u),root(&mut p,v));if a!=b{if w[u][v]<bw[a]{bw[a]=w[u][v];bu[a]=u as isize;bv[a]=v as isize;}if w[u][v]<bw[b]{bw[b]=w[u][v];bu[b]=u as isize;bv[b]=v as isize;}}}}}
        let mut merged=false;for r in 0..n{if bu[r]>=0{let(a,b)=(root(&mut p,bu[r] as usize),root(&mut p,bv[r] as usize));if a!=b{p[a]=b;components-=1;total+=bw[r];merged=true;}}}if !merged{return -1;}
    }total
}

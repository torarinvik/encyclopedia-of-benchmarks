/// Exact chromatic number through independent-set inclusion-exclusion.
#[no_mangle]
pub extern "C" fn exact_graph_coloring_inclusion_exclusion(x:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if x.is_null(){return -2}if len<2||len>44{return -1}let a=unsafe{std::slice::from_raw_parts(x,len)};let(nv,mv)=(a[0],a[1]);
 if nv<1||nv>7||mv<0||mv>21||len!=2+2*mv as usize{return -1}let(n,m)=(nv as usize,mv as usize);let mut adj=[[false;7];7];
 for e in 0..m{let(u,v)=(a[2+2*e],a[3+2*e]);if u<0||v<0||u>=nv||v>=nv||u==v{return -1}let(u,v)=(u as usize,v as usize);if adj[u][v]{return -1}adj[u][v]=true;adj[v][u]=true;}
 let lim=1usize<<n;let mut cnt=[0i64;128];cnt[0]=1;for mask in 1..lim{let bit=mask&mask.wrapping_neg();let v=bit.trailing_zeros() as usize;let rest=mask^bit;let mut allowed=rest;for u in 0..n{if adj[v][u]{allowed&=!(1<<u)}}cnt[mask]=cnt[rest]+cnt[allowed];}
 let mut chi=n as i64;for k in 1..=n{let mut sum=0i64;for mask in 0..lim{let mut term=1i64;let base=cnt[mask]-1;for _ in 0..k{term*=base}let parity=(n-mask.count_ones() as usize)%2;sum+=if parity==0{term}else{-term};}if sum>0{chi=k as i64;break;}}
 if cap<8||out.is_null(){return -2}let bytes=unsafe{std::slice::from_raw_parts_mut(out,8)};bytes.copy_from_slice(&chi.to_le_bytes());8
}

const N:usize=8; const M:usize=256;
fn put(o:*mut u8,p:usize,x:i64){unsafe{let b=(x as u64).to_le_bytes();for i in 0..8{*o.add(p+i)=b[i];}}}
#[no_mangle]
pub unsafe extern "C" fn metric_tsp_christofides(input:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if input.is_null()||len<2||len>65{return -1} let n0=*input;if n0<1||n0>N as i64||len!=1+n0 as usize*n0 as usize{return -1}let n=n0 as usize;
 let mut d=[[0i64;N];N];for i in 0..n{for j in 0..n{let w=*input.add(1+i*n+j);if w<0||w>10000||(i==j&&w!=0){return -1}d[i][j]=w;}}
 for i in 0..n{for j in 0..n{if d[i][j]!=d[j][i]{return -1}for k in 0..n{if d[i][j]>d[i][k]+d[k][j]{return -1}}}}
 let bytes=8*(n+2);if out.is_null()||cap<bytes{return -2}
 let mut edges=[(i64::MAX,0usize,0usize);28];let mut ec=0;for i in 0..n{for j in i+1..n{edges[ec]=(d[i][j],i,j);ec+=1}}edges[..ec].sort();
 let mut parent=[0usize;N];for i in 0..n{parent[i]=i}let mut tree=[[false;N];N];let mut used=0;
 for &(_,u,v) in edges[..ec].iter(){let(mut a,mut b)=(u,v);while parent[a]!=a{a=parent[a]}while parent[b]!=b{b=parent[b]}if a!=b{parent[b]=a;tree[u][v]=true;tree[v][u]=true;used+=1;if used==n-1{break}}}
 let mut odd=[0usize;N];let mut on=0;for i in 0..n{if (0..n).filter(|&j|tree[i][j]).count()%2==1{odd[on]=i;on+=1}}
 let full=(1usize<<on)-1;let mut dp=[i64::MAX/4;M];let mut pick=[usize::MAX;M];dp[0]=0;
 for mask in 1..=full{let i=mask.trailing_zeros() as usize;let rest=mask^(1<<i);for j in i+1..on{if rest&(1<<j)!=0{let tail=rest^(1<<j);let value=dp[tail]+d[odd[i]][odd[j]];if value<dp[mask]{dp[mask]=value;pick[mask]=j;}}}}
 let mut multi=[[0u8;N];N];for i in 0..n{for j in 0..n{if tree[i][j]{multi[i][j]=1}}}let mut mask=full;while mask!=0{let i=mask.trailing_zeros() as usize;let j=pick[mask];let(u,v)=(odd[i],odd[j]);multi[u][v]+=1;multi[v][u]+=1;mask^=(1<<i)|(1<<j);}
 let(mut st,mut rev)=(vec![0usize],Vec::new());while let Some(&v)=st.last(){if let Some(w)=(0..n).find(|&x|multi[v][x]>0){multi[v][w]-=1;multi[w][v]-=1;st.push(w)}else{rev.push(st.pop().unwrap());}}
 let mut seen=[false;N];let mut order=Vec::new();for v in rev.into_iter().rev(){if !seen[v]{seen[v]=true;order.push(v)}}let mut cost=0;for i in 0..n-1{cost+=d[order[i]][order[i+1]]}cost+=d[order[n-1]][0];put(out,0,cost);for i in 0..n{put(out,8*(i+1),order[i] as i64)}put(out,8*(n+1),0);bytes as i64
}

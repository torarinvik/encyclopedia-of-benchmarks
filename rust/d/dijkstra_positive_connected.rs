/// Compute source-zero shortest distances in a connected positive-weight graph.
fn put_i64(out:&mut [u8],index:usize,value:i64){out[index*8..index*8+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn dijkstra_positive_connected(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2{return -1}let x=std::slice::from_raw_parts(input,length);let nv=x[0];let mv=x[1];if !(1..=4).contains(&nv)||!(0..=6).contains(&mv)||length!=2+3*mv as usize{return -1}let n=nv as usize;let m=mv as usize;if m<n-1||m>n*(n-1)/2{return -1}
 let mut w=[[0i64;4];4];let mut adj=[[false;4];4];let mut neighbors=[[0usize;6];4];let mut degree=[0usize;4];for e in 0..m{let a=x[2+3*e];let b=x[3+3*e];let cost=x[4+3*e];if a<0||a>=nv||b<0||b>=nv||a==b||!(1..=255).contains(&cost)||adj[a as usize][b as usize]{return -1}let(a,b)=(a as usize,b as usize);adj[a][b]=true;adj[b][a]=true;w[a][b]=cost;w[b][a]=cost;neighbors[a][degree[a]]=b;degree[a]+=1;neighbors[b][degree[b]]=a;degree[b]+=1;}
 let mut seen=[false;4];let mut stack=[0usize;4];let mut top=1;stack[0]=0;seen[0]=true;while top>0{top-=1;let u=stack[top];for &v in &neighbors[u][..degree[u]]{if !seen[v]{seen[v]=true;stack[top]=v;top+=1;}}}if seen[..n].iter().any(|v|!*v){return -1}
 let mut dist=[i64::MAX;4];let mut done=[false;4];dist[0]=0;for _ in 0..n{let mut u=None;for i in 0..n{if !done[i]&&u.map_or(true,|j|dist[i]<dist[j]){u=Some(i)}}let Some(u)=u else{break};done[u]=true;for &v in &neighbors[u][..degree[u]]{if !done[v]&&dist[u]+w[u][v]<dist[v]{dist[v]=dist[u]+w[u][v]}}}
 if output.is_null()||capacity<n*8{return -2}let out=std::slice::from_raw_parts_mut(output,n*8);for i in 0..n{put_i64(out,i,dist[i])} (n*8) as i64
}

fn put_i64(out: &mut [u8], x: i64) { out[..8].copy_from_slice(&x.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn all_distances_sketch_bottom_k(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 104 { return -1; }
    let a=std::slice::from_raw_parts(input,length);let(n0,m0,k0,s0)=(a[0],a[1],a[2],a[3]);
    if n0<2||n0>10||m0<0||m0>n0*(n0-1)||k0<1||k0>n0||s0<0||s0>=n0||length!=4+n0 as usize+2*m0 as usize{return -1;}
    let(n,m,k,source)=(n0 as usize,m0 as usize,k0 as usize,s0 as usize);let mut rank=[0i64;10];let mut used=[false;10];
    for i in 0..n{let r=a[4+i];if r<0||r>=n0||used[r as usize]{return -1;}used[r as usize]=true;rank[i]=r;}
    let mut adj=[[false;10];10];for e in 0..m{let(u0,v0)=(a[4+n+2*e],a[5+n+2*e]);if u0<0||u0>=n0||v0<0||v0>=n0||u0==v0{return -1;}let(u,v)=(u0 as usize,v0 as usize);if adj[u][v]{return -1;}adj[u][v]=true;}
    let mut dist=[-1i64;10];let mut queue=[0usize;10];let(mut head,mut tail)=(0usize,0usize);dist[source]=0;queue[tail]=source;tail+=1;
    while head<tail{let u=queue[head];head+=1;for v in 0..n{if adj[u][v]&&dist[v]<0{dist[v]=dist[u]+1;queue[tail]=v;tail+=1;}}}
    let mut staged=[0i64;21];let mut count=0usize;
    for d in 0..n{for v in 0..n{if dist[v]!=d as i64{continue;}let mut less=0usize;for x in 0..n{if dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v]{less+=1;}}if less<k{staged[1+2*count]=v as i64;staged[2+2*count]=dist[v];count+=1;}}}
    staged[0]=count as i64;let words=1+2*count;let bytes=8*words;if output.is_null()||capacity<bytes{return -2;}let out=std::slice::from_raw_parts_mut(output,bytes);for i in 0..words{put_i64(&mut out[8*i..8*i+8],staged[i]);}bytes as i64
}

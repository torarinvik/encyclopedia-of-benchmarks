fn put_i64(out: &mut [u8], x: i64) { out[..8].copy_from_slice(&x.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn domination_local_reduction(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 135 { return -1; }
    let v=std::slice::from_raw_parts(input,length); let (n0,m0,p0)=(v[0],v[1],v[2]);
    if !(1..=12).contains(&n0) || !(0..=66).contains(&m0) || p0<0 || p0>=n0 || length!=3+2*m0 as usize { return -1; }
    let (n,m,p)=(n0 as usize,m0 as usize,p0 as usize); let mut a=[[false;12];12];
    for e in 0..m { let (u0,w0)=(v[3+2*e],v[4+2*e]); if u0<0||w0<=u0||w0>=n0{return -1;} let(u,w)=(u0 as usize,w0 as usize);if a[u][w]{return -1;}a[u][w]=true;a[w][u]=true; }
    let mut closed=[false;12];let mut exit=[false;12];let mut guard=[false;12];let mut prisoner=[false;12];closed[p]=true;
    for u in 0..n { if a[p][u]{closed[u]=true;} }
    for u in 0..n { if a[p][u] { for x in 0..n { if a[u][x]&&!closed[x]{exit[u]=true;break;} } } }
    for u in 0..n { if a[p][u]&&!exit[u] { for x in 0..n { if exit[x]&&a[u][x]{guard[u]=true;break;} } } }
    let mut np=0;for u in 0..n{if a[p][u]&&!exit[u]&&!guard[u]{prisoner[u]=true;np+=1;}}if np==0{return -1;}
    let mut ids=[0usize;12];let mut remap=[-1isize;12];let mut kept=0;
    for u in 0..n{if !guard[u]&&!prisoner[u]{ids[kept]=u;remap[u]=kept as isize;kept+=1;}}
    let k=kept+1;let leaf=k-1;let mut words=[0i64;25];words[0]=k as i64;
    for i in 0..kept{words[1+i]=ids[i] as i64;}words[1+kept]=-1;
    for i in 0..kept{for j in 0..kept{if a[ids[i]][ids[j]]{words[1+k+i]|=1i64<<j;}}}
    let rp=remap[p] as usize;words[1+k+rp]|=1i64<<leaf;words[1+k+leaf]=1i64<<rp;
    let count=1+2*k;let bytes=count*8;if output.is_null()||capacity<bytes{return -2;}
    let out=std::slice::from_raw_parts_mut(output,bytes);for i in 0..count{put_i64(&mut out[8*i..8*i+8],words[i]);}bytes as i64
}

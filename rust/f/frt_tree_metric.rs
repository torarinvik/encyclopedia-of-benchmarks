fn within(d: i64, beta: i64, level: i32) -> bool {
    if level >= 0 { d * 1024 <= beta * (1i64 << level) }
    else { d * 1024 * (1i64 << -level) <= beta }
}
fn put_i64(dst: &mut [u8], value: i64) { dst[..8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn frt_tree_metric(input: *const i64, length: usize,
                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 8 || length > 74 { return -1; }
    let a=std::slice::from_raw_parts(input,length);let n0=a[0];let beta=a[1];
    if !(2..=8).contains(&n0)||!(1024..=2047).contains(&beta){return -1;}
    let n=n0 as usize;if length!=2+n+n*n{return -1;}
    let mut perm=[0usize;8];let mut seen=[false;8];
    for i in 0..n{let p=a[2+i];if p<0||p>=n0||seen[p as usize]{return -1;}seen[p as usize]=true;perm[i]=p as usize;}
    let mut d=[[0i64;8];8];let mut maxd=0i64;let base=2+n;
    for i in 0..n{for j in 0..n{let x=a[base+i*n+j];if x<0||x>255||(i==j&&x!=0)||(i!=j&&x==0){return -1;}d[i][j]=x;maxd=maxd.max(x);}}
    for i in 0..n{for j in 0..n{if d[i][j]!=d[j][i]{return -1;}for k in 0..n{if d[i][j]>d[i][k]+d[k][j]{return -1;}}}}
    let mut high=0i32;while (1i64<<high)<maxd{high+=1;}
    let mut staged=[0i64;64];let mut clusters=[0u16;256];let mut next=[0u16;256];let mut count=1usize;clusters[0]=((1u16<<n)-1);
    for level in (-10..=high).rev(){let mut next_count=0usize;let td=1i64<<(level+13);
        for ci in 0..count{let mut remaining=clusters[ci];let mut done=0u16;
            while remaining!=0{let mut center=n;for p in 0..n{if remaining&(1u16<<perm[p])!=0{center=perm[p];break;}}if center==n{return -1;}
                let mut child=0u16;for v in 0..n{if remaining&(1u16<<v)!=0&&within(d[center][v],beta,level){child|=1u16<<v;}}if child==0{child=1u16<<center;}
                for u in 0..n{if done&(1u16<<u)!=0{for v in 0..n{if child&(1u16<<v)!=0{staged[u*n+v]=td;staged[v*n+u]=td;}}}}
                done|=child;remaining&=!child;next[next_count]=child;next_count+=1;
            }
        }clusters[..next_count].copy_from_slice(&next[..next_count]);count=next_count;
    }
    let bytes=8*n*n;if output.is_null()||capacity<bytes{return -2;}let dst=std::slice::from_raw_parts_mut(output,bytes);for i in 0..n*n{put_i64(&mut dst[8*i..],staged[i]);}bytes as i64
}

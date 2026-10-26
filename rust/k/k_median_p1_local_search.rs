const N:usize=12;const INPUT_MAX:usize=150;
fn put64(out:&mut[u8],x:i64){out[..8].copy_from_slice(&x.to_le_bytes());}
fn objective(d:&[i64;144],n:usize,c:&[usize],k:usize)->i64{let mut total=0;for i in 0..n{let mut best=i64::MAX;for &x in &c[..k]{best=best.min(d[i*N+x]);}total+=best;}total}
fn less(a:&[usize],b:&[usize],k:usize)->bool{a[..k]<b[..k]}
#[no_mangle]
pub unsafe extern "C" fn k_median_p1_local_search(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>INPUT_MAX{return -1;}let a=std::slice::from_raw_parts(input,length);let(n0,k0)=(a[0],a[1]);if n0<2||n0>12||k0<1||k0>4||k0>n0||length!=2+n0 as usize*n0 as usize+k0 as usize{return -1;}let n=n0 as usize;let k=k0 as usize;let mut d=[0i64;144];let mut p=2;for i in 0..n{for j in 0..n{let x=a[p];p+=1;if !(0..=1000).contains(&x){return -1;}d[i*N+j]=x;}}for i in 0..n{for j in 0..n{if d[i*N+j]!=(if i==j{0}else{d[i*N+j]})||d[i*N+j]!=d[j*N+i]||(i!=j&&d[i*N+j]==0){return -1;}for h in 0..n{if d[i*N+j]>d[i*N+h]+d[h*N+j]{return -1;}}}}
 let mut selected=[false;N];let mut centers=[0usize;4];for j in 0..k{let x=a[p];p+=1;if x<0||x>=n0||selected[x as usize]{return -1;}centers[j]=x as usize;selected[x as usize]=true;}centers[..k].sort_unstable();let mut current=objective(&d,n,&centers,k);
 loop{let mut best=current;let mut bestc=centers;let mut have=false;for leave in 0..k{for enter in 0..n{if selected[enter]{continue;}let mut cand=centers;cand[leave]=enter;cand[..k].sort_unstable();let value=objective(&d,n,&cand,k);if value<current&&(value<best||(value==best&&(!have||less(&cand,&bestc,k)))){best=value;bestc=cand;have=true;}}}if !have{break;}for &x in &centers[..k]{selected[x]=false;}centers=bestc;for &x in &centers[..k]{selected[x]=true;}current=best;}
 let bytes=8*(2+k);if output.is_null()||capacity<bytes{return -2;}let out=std::slice::from_raw_parts_mut(output,bytes);put64(out,current);put64(&mut out[8..],k as i64);for i in 0..k{put64(&mut out[16+8*i..],centers[i] as i64);}bytes as i64
}

const MAX_N: usize = 16;
fn mix(mut h: u64, mut x: u64) -> u64 { for _ in 0..8 { h ^= x & 255; h = h.wrapping_mul(1099511628211); x >>= 8; } h }
#[no_mangle]
pub extern "C" fn deep_clone_graph(a: *const i64, len: usize) -> i64 {
 if a.is_null() || len < 4 || len > 2+2*MAX_N { return -1; }
 let x=unsafe{std::slice::from_raw_parts(a,len)}; let n=x[0];let root=x[1];
 if n<1||n>MAX_N as i64||root<0||root>=n||len!=2+2*n as usize{return -1;}
 let n=n as usize;let root=root as usize;let mut labels=[0i64;MAX_N];let mut masks=[0u64;MAX_N];
 for i in 0..n {if x[2+i]<i32::MIN as i64||x[2+i]>i32::MAX as i64||x[2+n+i]<0||x[2+n+i] as u64 >= (1u64<<n){return -1;} labels[i]=x[2+i];masks[i]=x[2+n+i] as u64;}
 for i in 0..n {for j in 0..n {if ((masks[i]>>j)&1)!=((masks[j]>>i)&1){return -1;}}}
 let mut seen=[false;MAX_N];let mut cl=[0i64;MAX_N];let mut cm=[0u64;MAX_N];let mut stack=vec![root];let mut count=0;
 while let Some(u)=stack.pop(){if seen[u]{continue;}seen[u]=true;count+=1;cl[u]=labels[u];cm[u]=0;for v in 0..n{if (masks[u]>>v)&1!=0{cm[u]|=1u64<<v;if !seen[v]{stack.push(v);}}}}
 let mut h=mix(14695981039346656037,count as u64);h=mix(h,root as u64);for i in 0..n{if seen[i]{h=mix(h,cl[i] as u64);h=mix(h,cm[i]);}}h as i64
}

#[no_mangle]
pub unsafe extern "C" fn optimal_job_scheduling(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<4||n>194{return -1}let a=std::slice::from_raw_parts(v,n);if !(1..=16).contains(&a[0])||!(1..=8).contains(&a[1]){return -1}let p=a[0] as usize;let m=a[1] as usize;if n!=2+p*m+m*m||a[2..].iter().any(|&x|!(0..=1000).contains(&x)){return -1}
 let run=&a[2..2+p*m];let transfer=&a[2+p*m..];let mut cost=vec![0u32;p*m];for j in 0..m{cost[j]=run[j] as u32}for i in 1..p{for j in 0..m{let mut best=u32::MAX;for k in 0..m{best=best.min(cost[(i-1)*m+k]+transfer[k*m+j] as u32+run[i*m+j] as u32)}cost[i*m+j]=best}}
 let mut s=String::new();for i in 0..p{for j in 0..m{if j>0{s.push(',')}s.push_str(&cost[i*m+j].to_string())}if i+1<p{s.push('\n')}}if s.len()>cap||(!s.is_empty()&&out.is_null()){return -2}std::ptr::copy_nonoverlapping(s.as_ptr(),out,s.len());s.len() as i64
}

#[no_mangle]
pub unsafe extern "C" fn nearest_neighbour_algorithm(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<2||n>257{return -1}let a=std::slice::from_raw_parts(v,n);if !(1..=16).contains(&a[0]){return -1}let m=a[0] as usize;if n!=1+m*m||a[1..].iter().any(|&x|!(0..=1_000_000).contains(&x)){return -1}
 let mut seen=[false;16];let mut path=Vec::new();let mut current=0;for step in 0..m{seen[current]=true;path.push(current);if step+1==m{break}let mut best=m;let mut distance=0;for j in 0..m{if !seen[j]{let d=a[1+current*m+j];if best==m||d<distance{best=j;distance=d}}}current=best;}
 let bytes=path.iter().map(usize::to_string).collect::<Vec<_>>().join(",");if bytes.len()>cap||(!bytes.is_empty()&&out.is_null()){return -2}std::ptr::copy_nonoverlapping(bytes.as_ptr(),out,bytes.len());bytes.len() as i64
}

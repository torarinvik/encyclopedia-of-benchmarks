use std::slice;
#[no_mangle]
pub extern "C" fn flatten_nested_list(v:*const i64,n:usize)->i64{
 const OPEN:i64=i64::MIN;const CLOSE:i64=i64::MIN+1;
 if v.is_null()||n==0||n>255{return -1}let a=unsafe{slice::from_raw_parts(v,n)};if a[0]!=OPEN{return -1}
 let(mut depth,mut closed)=(0i32,false);let mut h:u64=0xcbf29ce484222325;
 for (i,&x) in a.iter().enumerate(){if x==OPEN{if closed||(depth==0&&i!=0){return -1}depth+=1;if depth>16{return -1}}else if x==CLOSE{if depth==0{return -1}depth-=1;if depth==0{closed=true;if i+1!=n{return -1}}}else{if depth==0||!(-1_000_000..=1_000_000).contains(&x){return -1}let u=x as u64;for b in 0..8{h^=((u>>(8*b))&255)as u64;h=h.wrapping_mul(0x100000001b3)}}}
 if depth!=0||!closed{return -1}h as i64
}

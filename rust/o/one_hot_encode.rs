#[no_mangle]
pub unsafe extern "C" fn one_hot_encode(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<2||n>33{return -1}let a=std::slice::from_raw_parts(v,n);if !(1..=32).contains(&a[0])||n!=a[0] as usize+1||a[1..].iter().any(|&x|!(0..=25).contains(&x)){return -1}
 let rows=a[0] as usize;let mut present=[false;26];for &x in &a[1..]{present[x as usize]=true}let mut map=[0usize;26];let mut cols=0;for i in 0..26{if present[i]{map[i]=cols;cols+=1}}let need=rows*cols;if need>cap|| (need>0&&out.is_null()){return -2}for r in 0..rows{for c in 0..cols{*out.add(r*cols+c)=(map[a[r+1] as usize]==c) as u8}}need as i64
}
